Ideas
=====

Using a js parser and walking an AST is a pain in the AST. Is there a lightweight
convention that I can use to add documentation that will be available at runtime?

Proposal
--------

    D = Doctor "MyClass", """
      MyClass is a pretty cool guy, eh docs up at Runtiem and doesn't afraid of
      anything!
    """

    module.exports = () ->
      self =
        name: D """
          An Observable with the name.
          
          Get name:
          
              self.name()
          
          Set name:
          
              self.name "Cool New Name"
  
        """, Observable "Dr. Duder"

        update: D """
          Update the swizwizzler
        """, ->

        documentation: D """
          Return the generated documentation for this guy!
        """, ->
          D.documentationFor(self)

Downsides
---------

Generates docs on each instance so probably not a good idea for simple data types
like `Point`s or `Rectangle`s, etc.

Alternative
-----------

JS Docstrings? Can it be done? This other duder used /** */ as JS docstrings
https://github.com/monolithed/__doc__/blob/master/index.js

    module.exports = ->
      """
        MyClass is a pretty cool guy, eh docs up like Snakelang and doesn't afraid of
        anything!
      """
    
      self = 
        name: Observable "Dr. Duder" # Can't put a docstring here :(
        update: ->
          """
            Update the swizwizzler
          """
        documentation: ->
          """
            Return the generated documentation for this guy!
          """
          # some regex shenanigans with `function.toSource`
          #
          # fn.toString().match(/function\([^)]*\) {("[^"\\]*(\\.[^"\\]*)*)"/)
          # 
          # Adapted from:
          # https://stackoverflow.com/questions/37032620/regex-for-matching-a-string-literal-in-java
          #
          
