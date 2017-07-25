module Crystal::Doc::Item
  def formatted_doc
    @generator.doc(self)
  end

  def formatted_summary
    @generator.summary(self)
  end

  macro def_to_json(type, properties)
    Item.def_to_json(nil, {{properties}})
  end

  macro def_to_json(type, **properties)
    Item.def_to_json({{type}}, {{properties}})
  end

  macro def_to_json(type, properties)
    def to_json({% if type %}value : {{type.id}}, {% end %}json : ::JSON::Builder)
      json.object do
        {% for key, value in properties %}
          {% keyid = (value[:property] || key).id %}
          _{{keyid}} = {{ (type ? "value" : "self").id }}.{{keyid}}

          {% unless value[:emit_null] %}
            unless _{{keyid}}.nil?
          {% end %}

            json.field({{key.id.stringify}}) do
              {% if value[:root] %}
                {% if value[:emit_null] %}
                  if _{{keyid}}.nil?
                    nil.to_json(json)
                  else
                {% end %}

                json.object do
                  json.field({{value[:root]}}) do
              {% end %}

              {% if value[:converter] %}
                if _{{keyid}}
                  {{ value[:converter] }}.to_json(_{{keyid}}, json)
                else
                  nil.to_json(json)
                end
              {% elsif value[:stringify] %}
                _{{keyid}}.to_s.to_json(json)
              {% else %}
                _{{keyid}}.to_json(json)
              {% end %}

              {% if value[:root] %}
                {% if value[:emit_null] %}
                  end
                {% end %}
                  end
                end
              {% end %}
            end

          {% unless value[:emit_null] %}
            end
          {% end %}
        {% end %}
      end
    end
  end

  macro def_to_json(**properties)
    Item.def_to_json(nil, {{properties}})
  end
end
