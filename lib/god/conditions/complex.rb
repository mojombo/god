module God
  module Conditions

    class Complex < PollCondition
      AND = 0x1
      OR  = 0x2
      NOT = 0x4

      def initialize()
        super

        @oper_stack = []
        @op_stack = []

        @this = nil
      end

      def valid?
        @oper_stack.inject(true) { |acc, oper| acc & oper.valid? }
      end

      def prepare
        @oper_stack.each { |oper| oper.prepare }
      end

      def new_oper(kind, op)
        oper = Condition.generate(kind, self.watch)
        @oper_stack.push(oper)
        @op_stack.push(op)
        oper
      end

      def this(kind)
        @this = Condition.generate(kind, self.watch)
        yield @this if block_given?
      end

      def and(kind)
        oper = new_oper(kind, 0x1)
        yield oper if block_given?
      end

      def and_not(kind)
        oper = new_oper(kind, 0x5)
        yield oper if block_given?
      end

      def or(kind)
        oper = new_oper(kind, 0x2)
        yield oper if block_given?
      end

      def or_not(kind)
        oper = new_oper(kind, 0x6)
        yield oper if block_given?
      end

      def test
        if @this.nil?
          # Although this() makes sense semantically and therefore
          # encourages easy-to-read conditions, being able to omit it
          # allows for more DRY code in some cases, so we deal with a
          # nil @this here by initially setting res to true or false,
          # depending on whether the first operator used is AND or OR
          # respectively.
          if 0 < @op_stack[0] & AND
            res = true
          else
            res = false
          end
        else
          res = @this.test
        end

        @op_stack.each do |op|
          cond = @oper_stack.shift
          eval "res " + ((0 < op & AND) ? "&&" : "||") + "= " + ((0 < op & NOT) ? "!" : "") + "cond.test"
          @oper_stack.push cond
        end

        res
      end
    end

  end
end
