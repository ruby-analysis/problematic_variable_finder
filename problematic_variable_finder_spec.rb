require_relative './problematic_variable_finder'

RSpec.describe ProblematicVariableFinder do
  let(:code) do
    <<-RUBY
      module Top
        module Thing
          class Something
            def self.egg
              @a_thing
            end

            class << self
              def thing
                @another_thing
                @this_one_too = 'this'
              end
            end

            def not_a_thing
              @not_a_thing
              @this_other_one_too = 'that'
            end

            def self.thing_2
              @@a_thing_2
              @this_other_one_too = 'hey'
            end

            class << self
              def another_thing_2
                @@another_thing_2 = 'yoho'
                @this_other_one_too ||= 'boom'
                $some_global = 'evil'
              end
            end
          end
        end
        $global = 'bad'
        $this_global
        class << self
          define_method :another_thing do
            @a = 2
          end

          attr_accessor :this
          attr_writer :that
          attr_reader :these
        end

        cattr_accessor :a
        cattr_writer :b
        cattr_reader :c
        mattr_accessor :d
        mattr_writer :e
        mattr_reader :f

        # not problem causing
        thread_cattr_accessor :g
        thread_cattr_writer :h
        thread_cattr_reader :i
        thread_mattr_accessor :j
        thread_mattr_writer :k
        thread_mattr_reader :l
      end
    RUBY
  end

  describe "#class_accessors" do
    it do
      result = described_class.new(code: code).class_accessors
      expect(result.length).to eq 9

      expect(result).to eq [
        {:type => :class_accessor, :line_number =>41, :name=>:this},
        {:type => :class_accessor, :line_number =>42, :name=>:that},
        {:type => :class_accessor, :line_number =>43, :name=>:these},

        {:type => :class_accessor, :line_number =>46, :name=>:a},
        {:type => :class_accessor, :line_number =>47, :name=>:b},
        {:type => :class_accessor, :line_number =>48, :name=>:c},

        {:type => :class_accessor, :line_number =>49, :name=>:d},
        {:type => :class_accessor, :line_number =>50, :name=>:e},
        {:type => :class_accessor, :line_number =>51, :name=>:f},
      ]
    end
  end

  describe "#class_instance_variables" do
    it do
      result = described_class.new(code: code).class_instance_variables
      expect(result.length).to eq 6

      expect(result).to eq [
        {:type => :class_instance_variable, :line_number=>5,  :name=>:@a_thing},
        {:type => :class_instance_variable, :line_number=>10, :name=>:@another_thing},
        {:type => :class_instance_variable, :line_number=>11, :name=>:@this_one_too},
        {:type => :class_instance_variable, :line_number=>22, :name=>:@this_other_one_too},
        {:type => :class_instance_variable, :line_number=>28, :name=>:@this_other_one_too},
        {:type => :class_instance_variable, :line_number=>38, :name=>:@a},
      ]
    end
  end

  describe "#global_variables" do
    it do
      result = described_class.new(code: code).global_variables
      expect(result).to eq [
        {type: :global_variable, line_number: 29, name: :"$some_global"},
        {type: :global_variable, line_number: 34, name: :"$global"},
        {type: :global_variable, line_number: 35, name: :$this_global, }
      ]
    end
  end

  describe "#class_variables" do
    it do
      result = described_class.new(code: code).class_variables
      expect(result).to eq [
        {:line_number=>21, :name=>:@@a_thing_2, :type=>:class_variable},
        {:line_number=>27, :name=>:@@another_thing_2, :type=>:class_variable}
      ]
      expect(result.length).to eq 2
    end
  end
end



