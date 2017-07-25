module Crystal::Doc
  record Main, body : String, program : Type, repository_name : String do
    def to_s(io : IO)
      to_json(io)
    end

    def to_jsonp(io : IO)
      io << "crystal_doc_search_index_callback("
      to_json(io)
      io << ")"
    end

    def to_jsonp
      String.build do |io|
        to_jsonp(io)
      end
    end

    Item.def_to_json(
      repository_name: {nilable: false},
      body: {nilable: false},
      program: {nilable: false}
    )
  end

  module JsonConverter
    extend self

    def to_json(array : Array, builder)
      builder.array do
        array.each { |item| to_json(item, builder) }
      end
    end

    Item.def_to_json(Type,
      html_id: {nilable: false},
      # json_path: {nilable: false},
      kind: {nilable: true},
      full_name: {nilable: false},
      name: {nilable: false}
    )

    Item.def_to_json(Crystal::Def,
      name: {nilable: false},
      args: {nilable: false, converter: JsonConverter},
      double_splat: {nilable: true, converter: JsonConverter},
      splat_index: {nilable: true},
      yields: {nilable: true},
      block_arg: {nilable: true, converter: JsonConverter},
      return_type: {nilable: true, stringify: true},
      visibility: {nilable: false, stringify: true},
      body: {nilable: true, stringify: true},
    )

    Item.def_to_json(Crystal::Macro,
      name: {nilable: false},
      args: {nilable: false, converter: JsonConverter},
      double_splat: {nilable: true, converter: JsonConverter},
      splat_index: {nilable: true},
      block_arg: {nilable: true, converter: JsonConverter},
      visibility: {nilable: false, stringify: true},
      body: {nilable: true, stringify: true},
    )

    Item.def_to_json(Crystal::Arg,
      name: {nilable: false},
      doc: {nilable: true},
      default_value: {nilable: true, stringify: true},
      external_name: {nilable: false, stringify: true},
      restriction: {nilable: true, stringify: true},
    )
  end
end
