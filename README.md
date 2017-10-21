# Zine OS

DIY E-Zine and Operating System

Interfaces
==========

FS Interface
------------

Read a blob from a path, returns a promise fulfilled with the blob object. The
blob is annotated with the path i.e.: blob.path == path

    read: (path) ->

Write a blob to a path, returns a promise that is fulfilled when the write succeeds.

    write: (path, blob) ->

Delete a file at a path, returns a promise that is fulfilled when the delete succeeds.

    delete: (path) ->

Returns a promise

    list: (directoryPath) ->


FileEntry Interface
-------------------

    path:
    size:
    type:

FolderEntry Interface
---------------------

    folder: true
    path:

Application Interface
---------------------

Application objects are views (they have an element, usually a UI window).

    element: DOMElement
    exit: -> # Exit the app and remove its element from the DOM
    send: -> Promise

Apps can communicate with each other by sending messages via the `send` method.
Since apps can be running inside iframes or other places all data needs to be
able to survive transit through the structured clone algorithm:
https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm

`send` returns a promise that is fulfilled with the result of the method or
rejected with an error. The first argument of send is the name of the method to
invoke in the application, the following arguments are the parameters to be
passed to that method.

`exit` gives the app a chance to respond and prompt to cancel to prevent losing
unsaved work. (TODO)

TODO: Add methods for binding/connecting observables.
TODO: Add methods for connecting streams.
