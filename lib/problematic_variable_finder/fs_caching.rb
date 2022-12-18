module ProblematicVariableFinder
  module FsCaching
    def store
      @store ||= PStore.new(".gem_problems.pstore")
    end

    def cache(key)
      return yield

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
