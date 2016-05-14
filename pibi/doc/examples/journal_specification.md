## Appendix: Journal Specification

The application journal should maintain a reference of actions committed while
running in Offline mode.

Journal entries are classified under one of three operation categories:

  1. `CREATE` entries
  2. `UPDATE` entries
  3. `DESTROY` entries

Each entry must contain at least the following data:

  1. scope
  2. resource id

Entry scopes define the means by which the journal and the API will locate the
resource identified by the supplied ID.

### Creating resources

`CREATE` entries must provide a client-generated id; the *shadow* id. When a
`CREATE` entry is successfully processed by the API, the shadow id will be mapped
to a genuine resource id. The shadow map is included in the journal API `SYNC` response.

Example `CREATE` entry:

    {
      scope:  "account:transactions",
      id:     "c123", // this is the shadow id
      data: {
        amount: 5
      }
    }

On `SYNC`, the journal must locate shadow resources (using a scope and a shadow id)
and substitute their shadow ids with the genuine ones in the shadow map.

Clients must make sure not to raise conflicts between shadow and genuine ids.
This can be easily satisfied by prefixing numeric IDs with a literal, such as "c144",
or "bf447". Genuine IDs will always be numeric and will not clash with any non-numeric IDs.

### Updating resources

`UPDATE` entries follow a similar structure to that of `CREATE` entries. The difference
lies in the semantics and processing of entries. Updating shadow resources need to
(obviously) utilize the shadow id, as no genuine is yet generated. The API must
therefore process `CREATE` entries and populate the shadow map accordingly *before*
attempting to process any `UPDATE` entries.

Journals containing `UPDATE` entries that reference no known shadow or genuine
id should be forcefully rejected.

> **Optimizing the Journal**
>
> When viable, `UPDATE` entries that reference a shadow resource should be
> entirely merged with the respective `CREATE` entry in
> order to avoid the overhead of a `CREATE` then an `UPDATE`. This should be
> possible given the fact that journal entry data is
> in a serialized `JSON` notation and can be easily differentiated and hence, mergeable.

### Destroying resources

*TODO*

## Operation ordering

    1. DELETE
    2. CREATE
    3. UPDATE

## Resource prioritization

The server must account for dependencies between resources. This is best explained with an example:

Say we have a `Transaction` resource that could be associated with any number of `Category` resources. In this scenario, the server must process records for the `Category` resources before processing those for `Transaction` resources.
