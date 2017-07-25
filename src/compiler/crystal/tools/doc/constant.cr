require "./item"

class Crystal::Doc::Constant
  include Item

  getter type : Type
  getter const : Const

  def initialize(@generator : Generator, @type : Type, @const : Const)
  end

  def doc
    @const.doc
  end

  def name
    @const.name
  end

  def value
    @const.value
  end

  def formatted_value
    Highlighter.highlight value.to_s
  end

  Item.def_to_json(
    name: {nilable: false},
    value: {nilable: true, stringify: true},
    doc: {nilable: true},
    summary: {nilable: true, property: :formatted_summary},
  )
end
