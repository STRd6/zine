
E = Symbol.for 'embalm'

module.exports = (I, self) ->
  self.extend
    embalm: (x) ->
      if !x?
        x
      else if Array.isArray(x)
        x.map self.embalm
      else if x[E]?
        x[E](x)
      else
        x

    embalmSymbol: ->
      E
