# Ruby Metaprogramming - Note 4

### Chapter 6 - Friday: Code That Writes Code

实战：实现类似 ActiveRecord 中的 validates 方法。

    class Person
      include CheckedAttributes
      attr_checked :age { |v| v >= 18 }
    end

    me = Person.new
    me.age = 39  # => OK
    me.age = 12  # => Exception

(一种 DSL? 很眼熟的样子。)

计划：

- 用 eval 实现
- 用常规方法实现
- 用 Class Macro 实现
- 用 Module 实现

#### Kernel#eval

eval，在运行时中，解析字符串代码并执行它。(代码的一种自我能力。) 在 Ruby 这种动态语言中，代码就是字符串，而不是二进制，这是和静态语方的区别。

示例：

    array = [10, 20]
    element = 30
    eval("array << element")  # => [10, 20, 30]

另一个示例，在运行时动态生成类似的方法：

    POSSIBLE_VERBS = ['get', 'put', 'post', 'delete']

    POSSIBLE_VERBS.each do |m|
      eval <<-end_eval
        def #{m}(path, *args, &b)
          r[path].#{m}(*args, &b)
        end
      end_eval
    end

**Binding Objects**

正如前面所说，代码不能运行在真空中，执行 eval 时，eval 必须运行在某个绑定上。

Ruby 提供了 Kernel#binding 方法来捕捉当前作用域，并返回一个连接此作用域的对象。此对象可以作用 eval 方法的第二个参数。

示例：

    class MyClass
      def my_method
        @x = 1
        binding  # 返回一个绑定对象
      end
    end

    b = MyClass.new.my_method  # 得到绑定对象 #<Binding:0x007f8028131e38>
    eval "@x", b  # => 1  在 b 这个绑定对象上执行 "@x"

其实这个绑定对象也是一种上下文。

如果 eval 忽略第二个参数，则默认是当前作用域的绑定。同时，Ruby 提供了一个顶层作用域的绑定对象：`TOPLEVEL_BINDING`。

    class AnotherClass
      def my_method
        eval "self", TOPLEVEL_BINDING
      end
    end

    AnotherClass.new.my_method  # => main

接着解释了 Ruby 下的调试利器 Pry 的工作原理，恍然大悟啊。Pry 为 Object 类型扩展了 pry 方法，即 Object#pry，在任何想断点的地方 (其实并不是真正的断点)，加上一句 `binding.pry`，当代码执行到此处时，先通过 binding 方法得到当前绑定对象，然后在这个对象上执行 pry 方法，pry 方法将打开一个 Ruby 解释器 (就和 irb 一样)，且这个解释器绑定对象就是刚用 binding 方法得到的绑定对象，因此你可以在这个解释器中用 eval 方法得到这个绑定对象上的任意值。

在这个解释器中执行 exit，退出解释器，代码将从刚才的 binding.pry 继续运行，直到下一个 binding.pry。(就像是 JavaScript 中的 yield 一样。)

突然想起以前调试 C 程序的时候，我们会用 scanf 来作为伪断点中断程序的执行。

**The irb Example**

irb 实际是怎么工作的，它接收输入，然后简单地每一行输入直接作为 eval 方法的第一个参数，传递给 eval 方法进行处理。

eval 方法的完整形式：

    eval(statements, @binding, file, line)

正如你可以在 bash 中再启动一个 bash，你也可以在 irb 中再启动一个嵌套的 irb。当启动 irb 时，你可以给它指定一个新的 binding，以替代默认的 binding 对象。(示例待补充)

**Stings of Code vs. Blocks**

eval 家族方法：

- eval
- class_eval
- instance_eval

截至到目前，我们一般认为，eval 的参数是字符串，而后二者的参数为 block。但实际上，后二者的参数，也可以是字符串。

    array = ['a', 'b', 'c']
    x = 'd'
    array.instance_eval "self[1] = x"

    array  # => ['a', 'd', 'c']

**The Trouble with eval()**

block 和 eval 之间的取舍。简洁的答案是，能用 block 的时候就不要用 eval。因为 eval 有安全风险，容易遭到类似 SQL 的注入攻击。

举个最简单的例子，你的程序可以接受用户的任意输入，然后用 eval 来执行它，没有做任何安全防范，如果用户输的是 \`rm -rf /\`，你的资料就全没了。

    # 这个太危险，千万别试!
    eval("`rm -rf /`")

    > irb
    # 你可以试这个
    eval("`touch test`")
    eval("`rm test`")

**Tainted Objects and Safe Levels**

Ruby 是如何来增加 eval 的安全的。

Ruby 会将潜在的非安全的对象设置为 tainted，比如从外部输入得到的对象。

    user_input = "User input: #{gets()}"
    # 输入 x = 1
    user_input.tainted?  # => true

Ruby 提供了一个全局变量 $SAFE 来设置安全等级，值从 0 到 3，0 最低，甚至允许格式化硬盘，3 最高，默认所有对象都是 tainted。等级 2，不允许在 eval 中对文件进行操作。高于 0 的等级都不允许对 tainted 的对象进行 eval。(在 irb 中 $SAFE 默认值是 0。)

    $SAFE = 1
    user_input = "User input: #{gets()}`
    # 输入 x = 1
    eval user_input  # => SecurityError: Insecure operation - eval

**The ERB Example**

最好的办法是让 eval 运行在一个 sandbox 中。应用之一就是 erb。

erb 主要就是通过 eval 实现的。它从 html 模板中抽出嵌入式 Ruby 语句，然后交给 eval 方法执行得到输出。

仔细想想，其实 Ruby 中的 Kernel#load 和 Kernel#eval 的原理是差不多的。

#### Quiz: Checked Attributes (Step 1)

实现 `add_checked_attribute(Person, :age)`。

    def add_checked_attrbute(klass, attribute)
      eval "
        class #{klass}
          def #{attribute}=(value)
            raise 'Invalid attribute' unless value
            @#{attribute} = value
          end

          def #{attribute}
            @#{attribute}
          end
        end
      "
    end

#### Quiz: Checked Attributes (Step 2)

目标：eval-free。使用 `class_eval` 和 `define_method`。

    def add_checked_attribute(klass, attribute)
      klass.class_eval do
        define_method "#{attribute=}" do |value|
          raise 'Invalid attribute' unless value
          instance_variable_set("#{attribute}", value)
        end

        define_method attribute do
          instance_variable_get "#{attribute}"
        end
      end
    end

#### Quiz: Checked Attributes (Step 3)

前面实现的校验是非常简单的，我们只是判断如何 value 为 nil 就抛出异常。现在我们要支持更复杂的验证。

使用示例：

    add_checked_attribute(Person, :age) { |v| v >= 18 }

实现：

    def add_checked_attribute(klass, attribute, &validation)
      klass.class_eval do
        define_method "#{attribute=}" do |value|
          raise 'Invalid attribute' unless validation.call(value)
          # ...
        end
        # ...
      end
    end

#### Quiz: Checked Attributes (Step 4)

现在我们要把这个校验放到每个类内部，就和 ActiveRecord 的 validates 很相似了。

使用：

    class Person
      attr_checked :age { |v| v >= 18 }
    end

实现，扩展 Class class：

    class Class
      def attr_checked(attribute, &validation)
        define_method "#{attribute=}" do |value|
          raise 'Invalid attribute' unless validation.call(value)
          # ...
        end
        # ...
      end
    end

#### Hook Methods

勾子函数。从来没有见过哪个语言有像 Ruby 这么多勾子，连被继承的事件都有勾子。

- 类被继承时
- 模块被类包含时
- 方法被定义时，取消定义时，移除时
- ...

示例：

    class String
      def self.inherited(subclass)
        puts "#{self} was inherited by #{subclass}"
      end
    end

    class MyString < String; end  # => String was inherited by MyString

更多的勾子函数：Module#included，Module#prepended，Module#method_added ...

#### Quiz: Checked Attributes (Step 5)

用 Hook Method 来实现 `attr_checked`。

使用：

    class Person
      include CheckedAttributes
      attr_checked :age { |v| v >= 18 }
    end

实现：

    module CheckedAttributes
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def attr_checked(attribute, &validation)
          define_method "#{attribute=}" do |value|
            # ...
          end
          # ...
        end
      end
    end

## Part II - Metaprogramming in Rails

### Chapter 8 - Preparing for a Rails Tour

    gem unpack activerecord -v=4.1.0

将 activerecord gem 的源码复印到当前目录下。

### Chapter 9 - The Desings of Active Record

    module ActiveRecord
      extend ActiveSupport::Autoload

      autoload :Base
      autoload :NoTouching
      autoload :Persistence
      # ...
      autoload :Validations
      # ...

    module ActiveRecord
      class Base
        extend ActiveModel::Naming
        # ...

        include Core
        include Persistence
        # ...

### Chapter 10 - Active Support's Concern Module

ActiveSupport::Concern 的由来，解决的问题。

**The Include-and-Extend Trick**

    module Validations
      def self.included(base)
        base.extend ClassMethods
        # ...
      end

      module ClassMethods
        def validates_length_of(*args)
        # ...
      end
      # ...
    end

这种技巧我们在前面展示过。当你 `include Validations` 时，实际等于 `extend Validations::ClassMethods`，做 include 来实现 extend 的功能，这样，你的代码中就可以统一使用 include 了。

缺点：

1. 每个 module 中都要写这么一坨相似的代码
1. 这样的 module 继承两层以上时失效。

ActiveSupport::Concern 就是有来解决这两个问题的。先看看它怎么用：

    require 'active_support'

    module MyConcern
      extend ActiveSupport::Concern

      def an_instance_metho; "an instance method"; end

      module ClassMethods
        def a_class_method; "a class method"; end
      end
    end

    class MyClass
      include MyConcern
    end

    MyClass.new.an_instance_method  # => "an instance method"
    MyClass.a_class_method  # => "a class method"

Concern 的实现：

    module Concern
      def self.extended(base)
        base.instance_variable_set(:@_dependencies, [])
      end

      def append_features(base)
        if base.instance_variable_defined?(:@_dependencies)
          base.instance_variable_get(:@_dependencies) << self
          return false
        else
          return false if base < self
          @_dependencies.each { |dep| base.include(dep) }
          super
          base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
          base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
        end
      end
      # ...
    end

重写了 `append_features()` 方法。具体原理暂略。

### Chapter 11 - The Rise and Fall of `alias_method_chain`

略。

### Chapter 12 - The Evolution of Attribute Methods

略。

### Chapter 13 - One Final Lesson

略。

## Part III - Appendixes

### A1. Common Idioms

**Mimic Methods**

private / protect 实际并不是关键字，而是 Class Macros，就像 `attr_reader`、`attr_writer`。

**Self Yield**

tap 的实现：

    class Object
      def tap
        yield self
        self
      end
    end

使用：

    ['a, 'b', 'c'].shift.tap { |x| puts x }.upcase
    # => A

**Symbol#to_proc()**

    names = ['bob', 'bill', 'jobs']
    names.map { |name| name.capitalize }
    names.map(&:capitalize)

`&:capitalize`，用 & 操作符将 symbol `:capitalize` 转换成 Proc。

### A2. DSL

略。

### A3. Spell Book

总结了本书的所讲到的所有技术概念，需要时查看即可。

Blank Slate：把所有方法都放在 `method_missing` 中处理。

Done@2017.9.23

最后，我对 Ruby 的总结就是，一门充满魔法的语言，灵活是很灵活。表面用起来很简单，实际比 Java 还复杂。概念太多。
