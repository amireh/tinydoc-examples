## Generating the dumps

In the legacy `pibid`, use the rake task `pibi:dump` to generate the dumps. You
can use the `OUT` environment variable to point to the folder that should contain
the JSON dumps.

Here's an example:

```shell
  cd /path/to/pibid
  OUT=dumps/2014.03.26 bundle exec rake pibi:dump
```

And this is an idea of what you should have after running the task:

```shell
kandie@cornholio:~/Workspace/Projects/pibid$ ls -alh dumps/2014.03.26
total 14M
drwxrwxr-x 2 kandie kandie  12K Mar 26 16:01 ./
drwxr-xr-x 5 kandie users  4.0K Mar 26 15:23 ../
-rw-rw-r-- 1 kandie kandie 360K Mar 26 15:23 00000-users-0.json
-rw-rw-r-- 1 kandie kandie 344K Mar 26 15:23 00001-users-1.json
-rw-rw-r-- 1 kandie kandie 335K Mar 26 15:23 00002-users-2.json
-rw-rw-r-- 1 kandie kandie 290K Mar 26 15:23 00003-users-3.json
-rw-rw-r-- 1 kandie kandie 121K Mar 26 15:23 00004-accounts-0.json
-rw-rw-r-- 1 kandie kandie 122K Mar 26 15:23 00005-accounts-1.json
-rw-rw-r-- 1 kandie kandie 122K Mar 26 15:23 00006-accounts-2.json
-rw-rw-r-- 1 kandie kandie 118K Mar 26 15:23 00007-accounts-3.json
-rw-rw-r-- 1 kandie kandie  60K Mar 26 15:23 00008-categories-0.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00009-categories-1.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00010-categories-2.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00011-categories-3.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00012-categories-4.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00013-categories-5.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00014-categories-6.json
-rw-rw-r-- 1 kandie kandie  57K Mar 26 15:23 00015-categories-7.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00016-categories-8.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00017-categories-9.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00018-categories-10.json
-rw-rw-r-- 1 kandie kandie  62K Mar 26 15:23 00019-categories-11.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00020-categories-12.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00021-categories-13.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00022-categories-14.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00023-categories-15.json
-rw-rw-r-- 1 kandie kandie  71K Mar 26 15:23 00024-categories-16.json
-rw-rw-r-- 1 kandie kandie  71K Mar 26 15:23 00025-categories-17.json
-rw-rw-r-- 1 kandie kandie  71K Mar 26 15:23 00026-categories-18.json
-rw-rw-r-- 1 kandie kandie  66K Mar 26 15:23 00027-categories-19.json
-rw-rw-r-- 1 kandie kandie  57K Mar 26 15:23 00028-categories-20.json
-rw-rw-r-- 1 kandie kandie  57K Mar 26 15:23 00029-categories-21.json
-rw-rw-r-- 1 kandie kandie  57K Mar 26 15:23 00030-categories-22.json
-rw-rw-r-- 1 kandie kandie  56K Mar 26 15:23 00031-categories-23.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00032-categories-24.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00033-categories-25.json
-rw-rw-r-- 1 kandie kandie  55K Mar 26 15:23 00034-categories-26.json
-rw-rw-r-- 1 kandie kandie  60K Mar 26 15:23 00035-categories-27.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00036-categories-28.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00037-categories-29.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00038-categories-30.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00039-categories-31.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00040-categories-32.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00041-categories-33.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00042-categories-34.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00043-categories-35.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00044-categories-36.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00045-categories-37.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00046-categories-38.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00047-categories-39.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00048-categories-40.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00049-categories-41.json
-rw-rw-r-- 1 kandie kandie  66K Mar 26 15:23 00050-categories-42.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00051-categories-43.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00052-categories-44.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00053-categories-45.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00054-categories-46.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00055-categories-47.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00056-categories-48.json
-rw-rw-r-- 1 kandie kandie  62K Mar 26 15:23 00057-categories-49.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00058-categories-50.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00059-categories-51.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00060-categories-52.json
-rw-rw-r-- 1 kandie kandie  64K Mar 26 15:23 00061-categories-53.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00062-categories-54.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00063-categories-55.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00064-categories-56.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00065-categories-57.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00066-categories-58.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00067-categories-59.json
-rw-rw-r-- 1 kandie kandie  67K Mar 26 15:23 00068-categories-60.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00069-categories-61.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00070-categories-62.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00071-categories-63.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00072-categories-64.json
-rw-rw-r-- 1 kandie kandie  60K Mar 26 15:23 00073-categories-65.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00074-categories-66.json
-rw-rw-r-- 1 kandie kandie  59K Mar 26 15:23 00075-categories-67.json
-rw-rw-r-- 1 kandie kandie  60K Mar 26 15:23 00076-categories-68.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00077-categories-69.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00078-categories-70.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00079-categories-71.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00080-categories-72.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00081-categories-73.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00082-categories-74.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00083-categories-75.json
-rw-rw-r-- 1 kandie kandie  62K Mar 26 15:23 00084-categories-76.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00085-categories-77.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00086-categories-78.json
-rw-rw-r-- 1 kandie kandie  65K Mar 26 15:23 00087-categories-79.json
-rw-rw-r-- 1 kandie kandie  64K Mar 26 15:23 00088-categories-80.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00089-categories-81.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00090-categories-82.json
-rw-rw-r-- 1 kandie kandie  61K Mar 26 15:23 00091-categories-83.json
-rw-rw-r-- 1 kandie kandie  62K Mar 26 15:23 00092-categories-84.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00093-categories-85.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00094-categories-86.json
-rw-rw-r-- 1 kandie kandie  63K Mar 26 15:23 00095-categories-87.json
-rw-rw-r-- 1 kandie kandie  49K Mar 26 15:23 00096-categories-88.json
-rw-rw-r-- 1 kandie kandie 174K Mar 26 15:23 00097-notices-0.json
-rw-rw-r-- 1 kandie kandie 174K Mar 26 15:23 00098-notices-1.json
-rw-rw-r-- 1 kandie kandie 174K Mar 26 15:23 00099-notices-2.json
-rw-rw-r-- 1 kandie kandie 174K Mar 26 15:23 00100-notices-3.json
-rw-rw-r-- 1 kandie kandie 4.1K Mar 26 15:23 00101-notices-4.json
-rw-rw-r-- 1 kandie kandie  76K Mar 26 15:23 00102-payment_methods-0.json
-rw-rw-r-- 1 kandie kandie  74K Mar 26 15:23 00103-payment_methods-1.json
-rw-rw-r-- 1 kandie kandie  74K Mar 26 15:23 00104-payment_methods-2.json
-rw-rw-r-- 1 kandie kandie  74K Mar 26 15:23 00105-payment_methods-3.json
-rw-rw-r-- 1 kandie kandie  78K Mar 26 15:23 00106-payment_methods-4.json
-rw-rw-r-- 1 kandie kandie  77K Mar 26 15:23 00107-payment_methods-5.json
-rw-rw-r-- 1 kandie kandie  77K Mar 26 15:23 00108-payment_methods-6.json
-rw-rw-r-- 1 kandie kandie  79K Mar 26 15:23 00109-payment_methods-7.json
-rw-rw-r-- 1 kandie kandie  83K Mar 26 15:23 00110-payment_methods-8.json
-rw-rw-r-- 1 kandie kandie  82K Mar 26 15:23 00111-payment_methods-9.json
-rw-rw-r-- 1 kandie kandie  82K Mar 26 15:23 00112-payment_methods-10.json
-rw-rw-r-- 1 kandie kandie  82K Mar 26 15:23 00113-payment_methods-11.json
-rw-rw-r-- 1 kandie kandie  816 Mar 26 15:23 00114-payment_methods-12.json
-rw-rw-r-- 1 kandie kandie 310K Mar 26 15:24 00114-recurrings-0.json
-rw-rw-r-- 1 kandie kandie 236K Mar 26 15:24 00115-transactions-0.json
-rw-rw-r-- 1 kandie kandie 234K Mar 26 15:24 00116-transactions-1.json
-rw-rw-r-- 1 kandie kandie 235K Mar 26 15:24 00117-transactions-2.json
-rw-rw-r-- 1 kandie kandie 235K Mar 26 15:24 00118-transactions-3.json
-rw-rw-r-- 1 kandie kandie 237K Mar 26 15:24 00119-transactions-4.json
-rw-rw-r-- 1 kandie kandie 235K Mar 26 15:24 00120-transactions-5.json
-rw-rw-r-- 1 kandie kandie 236K Mar 26 15:24 00121-transactions-6.json
-rw-rw-r-- 1 kandie kandie 236K Mar 26 15:24 00122-transactions-7.json
-rw-rw-r-- 1 kandie kandie 235K Mar 26 15:24 00123-transactions-8.json
-rw-rw-r-- 1 kandie kandie 233K Mar 26 15:24 00124-transactions-9.json
-rw-rw-r-- 1 kandie kandie 236K Mar 26 15:24 00125-transactions-10.json
-rw-rw-r-- 1 kandie kandie 234K Mar 26 15:24 00126-transactions-11.json
-rw-rw-r-- 1 kandie kandie 234K Mar 26 15:24 00127-transactions-12.json
-rw-rw-r-- 1 kandie kandie 231K Mar 26 15:24 00128-transactions-13.json
-rw-rw-r-- 1 kandie kandie 230K Mar 26 15:24 00129-transactions-14.json
-rw-rw-r-- 1 kandie kandie 223K Mar 26 15:24 00130-transactions-15.json
-rw-rw-r-- 1 kandie kandie  14K Mar 26 15:24 00131-transactions-16.json
-rw-rw-r-- 1 kandie kandie  41K Mar 26 15:24 00133-category_transactions-0.json
-rw-rw-r-- 1 kandie kandie  44K Mar 26 15:24 00134-category_transactions-1.json
-rw-rw-r-- 1 kandie kandie  44K Mar 26 15:24 00135-category_transactions-2.json
-rw-rw-r-- 1 kandie kandie  44K Mar 26 15:24 00136-category_transactions-3.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00137-category_transactions-4.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00138-category_transactions-5.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00139-category_transactions-6.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00140-category_transactions-7.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00141-category_transactions-8.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00142-category_transactions-9.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00143-category_transactions-10.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00144-category_transactions-11.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00145-category_transactions-12.json
-rw-rw-r-- 1 kandie kandie  46K Mar 26 15:24 00146-category_transactions-13.json
-rw-rw-r-- 1 kandie kandie  39K Mar 26 15:24 00147-category_transactions-14.json
```

## Importing

Two ways to run the importer: the recommended way is to use the fragments
importer which will resume from where it stopped if it encountered an error during
a previous import. Here's how to invoke it:


```shell
bundle exec rake pibi:import_from_legacy_fragments[../relative/path/to/pibid/dumps/2014.03.26]
```

Delete the file at `tmp/legacy_fragment_importer.txt` if you want to re-run the
importer from the beginning.

**Using the manual importer**

This will consume a single JSON dump fragment, useful for manually testing a
single fragment at a time:

```shell
bundle exec rake pibi:import_from_legacy[../relative/path/to/dump.json]
```

The importers are re-entrant in the sense that they will try to import only what
they find in the dumps. For example, if we have the following dump:

```json
{
  "users": [ {} ],
  "accounts": [ {} ]
}
```

The importer will attempt to import the available users first, then the accounts,
then terminate. So it's totally fine to feed the importer data for a single entity,
like categories or transactions.

Importing is atomic in that each entity imports are locked inside a transaction
so if importing a single item fails, none of the other entity items are committed.