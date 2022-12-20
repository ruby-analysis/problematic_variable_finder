module ProblematicVariableFinder
  module FsCaching
    def store
      @store ||= PStore.new(".problematic_variable_finder.pstore")
    end

    def cache(key)
      case @in_transaction
      when true
        store[key] ||= yield
      else
        result = store.transaction do
          @in_transaction = true
          store[key] ||= yield
        end
        @in_transaction = false
        result
      end
    end
  end
end
