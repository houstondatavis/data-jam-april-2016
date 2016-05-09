# coding: utf-8
import numpy as np
import os.path
import pandas as pd
import geopandas as gp
import seaborn
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from glob import glob
from matplotlib import rc, pyplot as plt
from viztricks import axes_grid
rc('figure', autolayout=True)


def main():
    args = parse_args()
    data = load_data(args.data, args.cache)
    for ptype in args.plot:
        if ptype == 'neighborhood':
            plot_by_neighborhood(data, args.geojson)
        elif ptype == 'overdue':
            plot_overdues(data)
        elif ptype == 'seasonality':
            plot_seasonality(data)
    plt.show()


def parse_args():
    cwd = os.path.dirname(__file__)
    orig_data = glob(os.path.join(cwd, '..', '*-mhhi.txt'))
    cache_file = os.path.join(cwd, '311.npz')
    nbr_geojson = os.path.join(cwd, '..', 'neighborhoods',
                               'boundaries-with-aliases.geojson')

    ap = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
    ap.add_argument('--data', nargs='+', default=orig_data,
                    help='Path(s) to original TSV data.')
    ap.add_argument('--cache', default=cache_file,
                    help='Path for cached data.')
    ap.add_argument('--geojson', default=nbr_geojson,
                    help='Path to neighborhood GeoJSON data.')
    ap.add_argument('plot', help='Plot type.', nargs='+',
                    choices=('neighborhood', 'overdue', 'seasonality'))
    args = ap.parse_args()
    if len(args.plot) != len(set(args.plot)):
        ap.error('Duplicate plot type')
    return args


def load_data(filenames, cache_file):
    if os.path.exists(cache_file):
        npz = np.load(cache_file)
        return pd.DataFrame.from_items(npz.items())
    # load it the slow way, from the TSV format
    data = load_tsv_data(filenames)
    # cache the loaded data for later
    np.savez(cache_file, **data)
    return data


def load_tsv_data(filenames):
    relevant_cols = [
        'NEIGHBORHOOD', 'DEPARTMENT', 'DIVISION', 'SR TYPE', 'SLA', 'STATUS',
        'SR CREATE DATE', 'DUE DATE', 'DATE CLOSED', 'Channel Type',
        'Median_HHI'
    ]
    date_cols = ['SR CREATE DATE', 'DUE DATE', 'DATE CLOSED']

    fragments = []
    for fname in filenames:
        d = pd.read_csv(fname, sep='\t', usecols=relevant_cols,
                        parse_dates=date_cols)

        # select only closed tickets
        d = d[d.STATUS == 'Closed']
        del d['STATUS']

        # drop missing values
        d.dropna(subset=['SLA'], inplace=True)

        # convert SLA to a timedelta
        d.SLA = pd.to_timedelta(d.SLA, unit='D')

        # add useful columns
        d['duration'] = d['DATE CLOSED'] - d['SR CREATE DATE']
        d['time/SLA ratio'] = d.duration / d.SLA

        # remove rows with negative duration
        d = d[d['time/SLA ratio'] >= 0]

        fragments.append(d)

    return pd.concat(fragments)


def plot_seasonality(data, n=8):
    groups = data.set_index('SR CREATE DATE').groupby('SR TYPE')
    counts = groups.resample('1W').size().reset_index(level=0).pivot(
                columns='SR TYPE', values=0)
    top_types = np.array(groups.size().sort_values()[-n:].index)[::-1]
    top_counts = counts[top_types]

    r = np.floor(np.sqrt(n))
    r, c = int(r), int(np.ceil(n / r))
    axes = top_counts.plot(subplots=True, sharex=True, sharey=True,
                           legend=False, layout=(r, c), figsize=(c*4, r*4))
    for name, ax in zip(top_types, axes.flat):
        ax.set_title(name)


def plot_overdues(data):
    col_names = [
        'DEPARTMENT', 'DIVISION', 'Channel Type'
    ]

    for col in col_names:
        order = data.groupby(col)['time/SLA ratio'].mean().sort_values().index
        plt.figure()
        seaborn.boxplot(x='time/SLA ratio', y=col, data=data, sym='',
                        order=order)


def plot_by_neighborhood(data, geojson_file):
    nbr = data.groupby('NEIGHBORHOOD')

    geonbr = gp.read_file(geojson_file).dropna()
    geonbr = geonbr.set_index('alias').join(nbr.mean())
    geonbr['# of Requests'] = nbr.size()
    geonbr['Income ($k)'] = geonbr['Median_HHI'] / 1000.

    cols = ['# of Requests', 'time/SLA ratio', 'Income ($k)']
    _, axes = axes_grid(len(cols))
    for col, ax in zip(cols, axes.flat):
        geonbr.plot(column=col, axes=ax)
        ax.set_title(col)

    seaborn.pairplot(geonbr[cols])


if __name__ == '__main__':
    main()
