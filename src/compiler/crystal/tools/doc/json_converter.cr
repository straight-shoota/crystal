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

    JSON.def_to_json(
      repository_name: true,
      body: true,
      program: true
    )
  end

  module JsonConverter
    extend self

    def to_json(array : Array, builder)
      builder.array do
        array.each { |item| to_json(item, builder) }
      end
    end

    JSON.def_to_json(Type,
      html_id: true,
      kind: true,
      full_name: true,
      name: true
    )

    JSON.def_to_json(Crystal::Def,
      name: true,
      args: {converter: JsonConverter},
      double_splat: {converter: JsonConverter},
      splat_index: true,
      yields: true,
      block_arg: {converter: JsonConverter},
      return_type: {converter: JSON::StringConverter},
      visibility: {converter: JSON::StringConverter},
      body: {converter: JSON::StringConverter},
    )

    JSON.def_to_json(Crystal::Macro,
      name: true,
      args: {converter: JsonConverter},
      double_splat: {converter: JsonConverter},
      splat_index: true,
      block_arg: {converter: JsonConverter},
      visibility: {converter: JSON::StringConverter},
      body: {converter: JSON::StringConverter},
    )

    JSON.def_to_json(Crystal::Arg,
      name: true,
      doc: true,
      default_value: {converter: JSON::StringConverter},
      external_name: {converter: JSON::StringConverter},
      restriction: {converter: JSON::StringConverter},
    )
  end
end
