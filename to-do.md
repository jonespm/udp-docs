# UDP documentation to do

## Implementation
* Setting up Canvas Data, Live Events, Canvas API
* Key rotation

## Routing signatures
* Endpoint has routing signatures
* Routing signatures correspond to processing routes
* Can see what routing and processing was applied to events in the Endpoint response

## Documentation
* Introduction to common modeling (pull from deck)
* Institutional extensions to the UCDM
* Better description of table types
* Fix all lower case?

* Joining event and relational data
  - What entities are joinable?
  - use ucdm_id values from events to get context dataset
  - query for context, extract ucdm keys, query event store

## UDP Resources
* For any particular institution, generate the names for all of the Resources in the UDP - https://docs.google.com/spreadsheets/d/1-aOhQp1O0y9eVHig7y-L8qM5FpaaSx448Er_LKVSdTE/edit#gid=1688061250

## UCDM Modeling
- Quiz item
- Quiz item response

* Document how the 1:many relationships in our entity relationships – more doc notes?
* Dates should be dates & times
* Check the jurisdiction values for entities, elements, option sets
* Break up RefWorkflowState into Entity-specific workflow state option assets
* What is up with Maternal, Paternal, and Parental option set tables?

## UCDM Resources
Break out UCDM documentation into per Entity pages
* Element definitions
* 1:many relationship and modeling notes.
* Root table in UCDM relational
* Queries
