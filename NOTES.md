Apps and Associations
---------------------

Would be cool to have apps that can auto-update and register associations.

What's needed?

name: String
icon: Emoji (maybe could get from favicon in url?)
src: URL
associations: associations for paths and types that this app can open
launchAtStartup: false|true|"hidden"  whether this application auto-starts
width:
height:

We could also have json urls that point to a package that is installed. The
package could contain its own metadata. We can cache it locally and check for
updates periodically.

We need a way to persist the list of apps locally, maybe just a file in the
`/System/` folder. Perhaps `/System/apps.json`

JavaScript Stuff
----------------

Symbols cannot be cloned through postMessage.

AWS
---

CloudFront automatic gzip doesn't handle application/custom+json types, so stick
with the basics!
