var csv = require('csv-stream');
var fs = require('fs');
var _ = require('lodash');
var request = require('request');
var JSONStream = require('JSONStream');
var streamToPromise = require('stream-to-promise');

var SOURCE_DATA_PATH = './311-Public-Data-Extract-2015-tab.txt';
var NEIGHBORHOODS_GEOJSON_PATH = './neighborhoods/boundaries.geojson';
var NEIGHBORHOODS_ALIASES_GEOJSON_PATH = './neighborhoods/boundaries-with-aliases.geojson';

var API_ENDPOINTS_FOR_NEIGHBORHOODS = 'https://api.everyblock.com/gis/houston/neighborhoods/?token=90fe24d329973b71272faf3f5d17a8602bff996b';

/**
 * Main
 */

// Checks whether local copy of geojson already exists
fs.access(NEIGHBORHOODS_GEOJSON_PATH, fs.R_OK | fs.W_OK, function(err) {
  if(err) {
    // If local copy does not exist, get them from the api before assigning the aliases
    getNeighborhoodGeojson()
      .then(getNeighborhoodNames)
      .then(setNeighborhoodAliases)
      .then(writeAliases);
  } else {
    // Otherwise, go ahead and just assign aliases.
    getNeighborhoodNames()
      .then(setNeighborhoodAliases)
      .then(writeAliases);
  }
});


/**
 * Workflow functions
 */


function getNeighborhoodGeojson(){
  var writeNeighborhoods = fs.createWriteStream(NEIGHBORHOODS_GEOJSON_PATH);
  var writePromise = streamToPromise(writeNeighborhoods);

  // Grab data from api, parse out JSON from the "data" key,
  // and write the result data to our local geojson file.
  request(API_ENDPOINTS_FOR_NEIGHBORHOODS)
    .pipe(JSONStream.parse('data'))
    .pipe(JSONStream.stringify(false))
    .pipe(writeNeighborhoods);

  // Return a promise so that when the write is done,
  // we can continue with other steps.
  return writePromise.then(function(writeBuffer){
    console.log(`Copied geojson from API at ${API_ENDPOINTS_FOR_NEIGHBORHOODS}`);
    return writeBuffer;
  });
}


function getNeighborhoodNames(){
  var readNeighborhoods = fs.createReadStream(NEIGHBORHOODS_GEOJSON_PATH);
  var readPromise = streamToPromise(readNeighborhoods)

  var neighborhoods = [];

  // Read from the local geojson, and get the "name" of each feature.
  // Push each of the names to a `neighborhoods` array.
  readNeighborhoods
    .pipe(JSONStream.parse('features.*.properties.name'))
    .on('data', function(data){
      neighborhoods.push({name: data});
    });

  // Pass the `neighborhoods` array out through the promise so that
  // when the file has been parsed through for names, the array can be used.
  return readPromise.then(function(){
    console.log('Grabbed neighborhoods names.');
    return neighborhoods;
  });
}

function setNeighborhoodAliases(neighborhoods){
  var sourceDataSteam = fs.createReadStream(SOURCE_DATA_PATH);
  var setPromise = streamToPromise(sourceDataSteam);

  var csvStreamOptions = { delimiter : '\t', endLine : '\n', escapeChar : '"', enclosedChar : '"'};
  var csvStream = csv.createStream(csvStreamOptions);

  // Read the source data, and for each `NEIGHBORHOOD`, check for a matching
  // name on the main `neighborhoods` array.  If a value from the source data
  // and a name in the `neighborhoods` array matches, set the alias in the
  // `neighborhoods` array.
  sourceDataSteam.pipe(csvStream)
    .on('column', function(key, value){
      if(key === 'NEIGHBORHOOD'){
        var matcher = cleanNeighborhoodName(value);
        _.forEach(neighborhoods, _.partial(setNeighborhoodAlias, _, matcher, value));

        // Stop reading the source file early if we finish assigning aliases.
        if(!_.find(neighborhoods, _.negate(hasAlias))){
          sourceDataSteam.destroy();
        }
      }
    });


  // Pass the `neighborhoods` array out through the promise so that
  // when all aliases have been set, the array can be used.
  return setPromise.then(function(){
    console.log(`Set neighborhoods aliases from ${SOURCE_DATA_PATH}.`);
    return neighborhoods;
  });
}

function writeAliases(neighborhoods){
  var readNeighborhoods = fs.createReadStream(NEIGHBORHOODS_GEOJSON_PATH);
  var writeNeighborhoodAliases = fs.createWriteStream(NEIGHBORHOODS_ALIASES_GEOJSON_PATH);

  var writePromise = streamToPromise(writeNeighborhoodAliases);

  // Read the current local geojson and modify the `properties` of each feature
  // to include the `alias`.  Write the data with the aliases to a new file.
  readNeighborhoods
    .pipe(JSONStream.parse())
    .on('data', function(data){
      _.forEach(data.features, function(feature) {
        var alias = _.find(neighborhoods, {name: feature.properties.name}).alias;
        feature.properties.alias = alias;
      });
    })
    .pipe(JSONStream.stringify(false))
    .pipe(writeNeighborhoodAliases)


  // Return a promise so that when the write is done,
  // we can continue with other steps if needed.
  return writePromise.then(function(writeBuffer){
    console.log(`Aliases written to ${NEIGHBORHOODS_ALIASES_GEOJSON_PATH}!`);
    return writeBuffer;
  });
}


/**
 * Neighborhood name utility functions
 */

function setNeighborhoodAlias(neighborhood, cleanFoundNeighborhood, alias){
  var cleanGeojsonName = cleanNeighborhoodName(neighborhood.name);
  if(cleanGeojsonName === cleanFoundNeighborhood){
    neighborhood.alias = alias;
    return false;
  }
}

function hasAlias(neighborhood){
  return neighborhood.alias;
}

function cleanNeighborhoodName(neighborhood){
  // Some neighborhoods are annoyingly named/mis-matched. :(
  var weirdClean = neighborhood.replace(/(Memorial Park)$/g, 'Memorial P').replace(/(BRAESWOOD PLACE)/g, 'BRAESWOOD');
  var regularClean = weirdClean.toUpperCase().replace(/-|\/| /g, '');
  return regularClean;
}