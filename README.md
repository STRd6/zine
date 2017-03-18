# zine
DIY E-Zine and Operating System


Interfaces
----------

FS Interface
------------

Read a blob from a path, returns a promise fulfilled with the blob object.

    read: (path) ->

Write a blob to a path, returns a promise that is fulfilled when the write succeeds.

    write: (path, blob) ->

Delete a file at a path, returns a promise that is fulfilled when the delete succeeds.

    delete: (path) ->

Returns a promise

    list: (directoryPath) ->
      

FileEntry Interface
------------------

    path: 
    size: 
    type: 

FolderEntry Interface
---------------------

    folder: true
    path:
