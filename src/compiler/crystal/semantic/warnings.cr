module Crystal
  class Program
    def report_warning(node : ASTNode, message : String)
      return unless self.warnings.all?
      return if self.ignore_warning_due_to_location?(node.location)

      self.warning_failures << node.warning(message)
    end

    def report_warning_at(location : Location?, message : String)
      return unless self.warnings.all?
      return if self.ignore_warning_due_to_location?(location)

      if location
        message = String.build do |io|
          io << "warning in line " << location.line_number << "\nWarning: "
        end
      end

      self.warning_failures << message
    end
  end
end
