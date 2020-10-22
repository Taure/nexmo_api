nexmo_api
=====

Build
-----

    $ rebar3 compile


Configure
---------

Add the following to your `sys.config`:

```
{nexmo_api, [
    {credentials, [
        {key, <<"YOUR KEY">>},
        {secret, <<"YOUR SECRET">>}
    ]},
    {from_alias, <<"FROM_ALIAS">>}
]}
```
