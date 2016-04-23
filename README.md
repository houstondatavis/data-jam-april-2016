# data-jam-april-2016

## Variable Description

All of the public 3-1-1 Service Requests from the Lagan 311 system

| Variable | Description |
| ---------------- | ------------------ |
| CASE NUMBER | Unique case ID |
| SR LOCATION | The location the service request is being called in for |
| COUNTY | The county of the service request |
| DISTRICT | The geocoded Council district of the service request |
| NEIGHBORHOOD | The neighborhood of the geocoded service request |
| TAX ID | The HCAD property tax ID for the service request |
| MANAGEMENT DISTRICT | The management district of the service request location |
| DEPARTMENT | The department the service request is directed to (could be virtual department, e.g. 311 Help Line) |
| DIVISION | The division the service request is directed to (e.g. Knowledge) |
| SR TYPE | The service request type |
| QUEUE | The queue the service request is put into |
| SLA | The service level agreement days. The number of days the department has from the create date to address the service request |
| STATUS | Status of the service request. Closed does not necessarily mean the SR was solved to meet citizen needs. |
| SR CREATE DATE | The create date of the service request |
| DUE DATE | The due date of the service request based on the SLA days |
| DATE CLOSED | The date the service request is closed |
| OVERDUE | If the number is negative, it means the number days the service request was completed before the SLA was due (or, how many days are remaining to the SLA if the case is still open). If positive, it means the number of days the service request was complete after the SLA was due (or, how many days past the SLA if the case is still outstanding) |
| Title | Title |
| LATITUDE | Decimal Degrees longitude |
| LONGITUDE | Decimal Degrees longitude |
| Channel Type | How the ticket came in |
