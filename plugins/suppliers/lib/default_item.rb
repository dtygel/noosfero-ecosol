module DefaultItem

  module ClassMethods

    def default_item field, options = {}

      # in case them doesn't exist
      class_eval <<-CODE
        def #{field}
          self["#{field}"]
        end unless self.new.respond_to? "#{field}"
        def #{field}= value
          self["#{field}"] = value
        end unless self.new.respond_to? "#{field}="
      CODE

      define_method "delegated_#{field}" do
        delegate_to = options[:delegate_to]
        if delegate_to.is_a? Symbol
          object = self.send delegate_to
          value = if object then object.send field else self.send "own_#{field}" end rescue nil
        else
          value = instance_eval &delegate_to
        end
        value
      end

      define_method "#{field}_with_default" do
        prefix = options[:prefix] || 'default'
        apply_default = self.send(options[:if] || "#{prefix}_#{field}")
        apply_default ||= options[:default] if apply_default.nil?
        if apply_default or (own = if self.class.column_names.include?(field) then self[field] else self.send "own_#{field}" end).nil?
          self.send "delegated_#{field}"
        else
          own
        end
      end
      alias_method_chain "#{field}", :default

      # better names aliases
      alias_method "original_#{field}", "delegated_#{field}"
      alias_method "own_#{field}", "#{field}_without_default"
      alias_method "own_#{field}=", "#{field}="

      include DefaultItem::InstanceMethods
    end
  end

  module InstanceMethods
  end

end

ActiveRecord::Base.extend DefaultItem::ClassMethods
