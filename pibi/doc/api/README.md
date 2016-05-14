Welcome to the Pibi API Documentation
===========================================

The Pibi public API allows you to manage finances directly just as if you were
to use the <a href="https://www.pibiapp.com">primary web interface</a>.

To get started, you'll want to review the general basics, including the
information below and the page on <a href="authentication.html">authentication</a>.

Schema
------

- All API access is over HTTPS.
- All API responses are in <a href="http://www.json.org/">JSON format</a>, and
  adhere to the [JSON API](http://jsonapi.org/format) specification as much as
  possible
- Date objects are accepted in one of two formats for convenience:
  1. [ISO-8601](http://en.wikipedia.org/wiki/ISO_8601) timezone-aware date
     strings (which is the default output of `Date().toJSON()` in JavaScript)
  2. A string format of `MM/DD/YYYY` where `MM` is the zero-padded month of the
     year, `DD` is the zero-padded day of the month, and `YYYY` is the year.

Authentication
--------------

API authentication is provided in 3 schemes as explained below.

**Using HTTP Basic Auth**

    curl -u "your@email.com:password" https://api.pibiapp.com/sessions

**Using Access Tokens**

By specifying a custom `X-Access-Token` HTTP header with an access token you've
generated:

    curl -H 'X-Access-Token: ACCESS_TOKEN" https://api.pibiapp.com/sessions

Read more about <a href="authentication.html">how to get access tokens.</a>

**Using Cookies (from a browser and a whitelisted domain)**

For brevity, I'll assume you're using jQuery:

```javascript
$.ajax({
  url: 'https://api.pibiapp.com/sessions',
  type: 'POST',
  xhrFields: {
    withCredentials: true // required for CORS + Cookies
  },
  headers: {
    'Accept': 'application/json; charset=UTF-8',
    'Content-Type': 'application/json; charset=utf-8'
  },
  data: {
    email: 'your@email.com',
    password: 'password'
  }
});
```

> **Note**
>
> You will need to have your domain whitelisted in order to authenticate using
> CORS. [Get in touch](mailto:support@pibiapp.com) if you need this.

About this Documentation
------------------------

This documentation is generated directly from the Pibi API code itself.
You can generate this documentation yourself if you've set up a
local Pibi API environment following the instructions on
<a href="https://www.github.com/amireh/pibi/wiki">Github</a>,
and run the following command from your Pibi directory:

    bundle exec rake doc:api

