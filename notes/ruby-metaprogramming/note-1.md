# Ruby Metaprogramming - Note 1

Note for *Ruby MetaProgramming* Book (second version).

## Part I - Metaprogramming Ruby

### Chapter 1 - The M Word

解释 MetaProgramming 的意思。

元编程，生成代码的代码，类似制造工具的工具。机床是一种先进的工具，它可以帮你快速精确地制造其它各种各样的工具，免去了繁琐原始的手工打造过程。元编程，就是类似机床作用的代码。广义上，我觉得 C++ 中的模板，Java 中的范型，注解，反射，都可以看做是一个元编程，但 Ruby 的元编程无疑比它们强大。

程序有静态编译时和运行时，需要编译的语言才有静态编译时，Ruby 不需要编译，没有编译时，都是运行时，所有变量和方法都是在运行时定义出来的，尤其是方法，所有方法都是运行时动态创建出来，甚至 class 也是，让人大吃一惊，这和传统语言完全不一样。你可以理解成，像 C++ 这种静态语言，编译期就像是制造过程，编译完后就得到了制造结果 (各种方法)，运行时就直接使用制造出来的工具 (方法) 执行各种操作，速度自然快，而 Ruby 这种动态语言，制造过程是在运行时，边运行边制造各种工具 (方法)，然后再用这些工具 (方法) 去执行各种操作，速度是自然更慢。静态语言在编译期就能发现一些错误，而动态语言只能在执行的时候才能发现。

introspection，自省，对象可以在运行时查看自身，比如有哪些变量，方法，属于什么类。像 C/C++ 这种静态语言几乎无法做到，因为静态编译之后，什么变量，方法，统统都消失了，变成了二进制代码，Java 利用反射功能可以做到，而 Ruby 是很方便地可以做到，这是动态语言的优势。

Ruby 中查看一个对象的 class:

    my_obj.class  # => Greeting

查看实例方法，false 表示不包括从父类继承的方法，只包括在本类中定义的方法。作用在类上，而不是实例上：

    my_obj.instance_methods(false)    # => Error
    Greeting.instance_methods(false)  # => [:welcome]

查看所有方法 (作用在实例和类上得到的值并不完全相同)：

    my_obj.methods
    Greeting.methods

从 Chapter 2 了解到，实际上：

    String.instance_methods == "abc".methods  # => true，即类的实例方法，等于实例的方法
    String.methods == "abc".methods           # => false，即类的方法，不等于实例的方法

查找方法：

    my_obj.methods.grep(/.../)

查看对象的实例变量：

    my_obj.instance_variables    # => [:@text]
    Greeting.instance_variables  # ?? 两者的结果会是一样吗，表示怀疑，待确证，因为变量是存储在对象上的，而不是类上的

通过证明，instance_variables 作用在实例和类上的值是不一样的，即使用是作用在实例上，也只能反应当前时刻的成员变量，因为成员变量在 Ruby 中是可以在运行时动态创建出来的。比如下面这个例子：

    class MyClass
      def my_method
        @v = 1
      end
    end

    > obj = MyClass.new
    > MyClass.instance_variables  # => []
    > obj.instance_variablse      # => []

    > obj.my_method
    > MyClass.instance_variables  # => []
    > obj.instance_variablse      # => [:@v]

### Chapter 2 - Monday: The Object Model

解释 Ruby 的对象模型，因为之前已经理解了，所以相当于是复习。关键点在于理解，`class MyClass`，当用 class 语句定义一个类时，实际在生成一个 Class 的对象，即等于 `MyClass = Class.new(...)`，类也是对象，但它是常量，而不是变量，因为首字母是大写。

Ruby 允许给已存在的类扩展任意方法，Ruby 中称之为打开类 (Open Classes)。

    class String
      def to_alphanumeric
        gsub(/[^\w\s]/, '')
      end
    end

当用 class 定义一个已存在的类时，实际是会重新打开这个已存在类并给它增加新的方法。所以说，Ruby 中的 class 更像是一个作用域操作符 (后面会讲到作用域 scope)，而不是一个类定义符。

类是在运行时动态创建出来的：

    3.times do
      class C
        puts 'Hello'
      end
    end

    # 执行结果
    Hello
    Hello
    Hello

Open Classes 带来的问题，会不小心覆盖原来存在的方法，解决办法之一：Monkeypatch。暂时还不了解它。

#### 类的真相

一句话概括，就是：类也是对象。

    "hello".class  # => String
    String.class   # => Class

    Class.instance_methods(false)  # => [:allocate, :new, :superclass]

所以现在知道了 `obj = MyClass.new()` 中 new 方法是从何而来的了。

    Array.superclass        # => Object
    Object.superclass       # => BasicObject
    BasicObject.superclass  # => nil

(把 Ruby 和 Javascript 联系起来看，还蛮多相似的地方的。)

##### Modules

Class 的 superclass 是什么呢？

    Class.superclass  # => Module

这意味着，每一个 class 都是一个 module，更准确地说，是一个拥有 [:new, :allocate, :superclass] 实例方法的 module。

module 和 class 几首没有什么差别，只是在使用有一些不同，我们更倾向于用 module 来实现组合，用 class 来实现继承或实例化。对于 module 来说，我们是将它 include，而对于 class 来说，我们继承自它，或用它 new 一个实例。

module 的另一个作用是实现命名空间。

一张图展示到目前为止所了解的 Object / Class / Module 之间的关系：

    calss MyClass; end
    obj1 = MyClass.new
    obj2 = MyClass.new

![](../art/ruby-object-inherit.png)

由于类名实际是一个常量对象，因此，你可以用一个变量指向它：

    my_class = MyClass

这是一种很 powerful 的能力，Java / C++ 并不具备，它可以让你少写很多代码。

这也让我相应地理解了，在 React 中的 navigator 中，为什么我可以让一个变量指向定义的 class，因为在 React 中，定义的 class 实际是一个构造函数，而构造函数也可以算是一种常量：

    const COMPONENTS = {
      App,
      CohortList,
      CohortCard,
      CohortCardMobile
    }

    let Component = COMPONENTS[componentName]
    if (Component === undefined) {
      Component = App
    }
    ReactDOM.render(<Component {...props}/>, document.getElementById(elementId))

##### Constants

在 Ruby 中，约定首字母大写的为常量，比如类名，模块名，类的常量成员。

常量的路径：

    X = 'a root-level constant'
    module M
      X = 'a constant in M'
      class C
        X = 'a constant in C'
      end
      puts ::X
      puts X
      puts C::X
    end

    puts X
    puts M::X
    puts M::C::X

    M.constants  # => [:X, :C]，:C 是类名

另外，可以在代码的任意地方使用 `Module.nesting` 得到当前的路径。

##### Objects and Classes Wrap-Up

再次总结什么是实例对象，什么是类。对象和类的区别。

概括地说，对象存储实例变量，另外有一个指向 class 的链接。但它不存储任何方法。方法存储在类中，被称之为实例方法。

类，也是对象，但是特殊的对象，是 Class 的实例对象，它用来存储实例方法，和一个指向 superclass 的链接。

##### Using Namespaces

无须多言，module 的另一个功能。

load 和 require 的区别。它们被设计于不同的用途，load 用来执行代码，而 require 用来导入库。因此前者每 load 一次，代码就会执行一次，而 require，无论 require 多少次，都只会执行一次。

`load('test.rb', true)`，load 方法指定第二个参数为 true，可以把 load 进来的代码用一个匿名的 moduel 包裹起来，以免里面定义的变量或方法污染全局。

继续补充 Ruby 类之间的关系图：

1. Object 的 class 是什么?
1. Class 的 class 是什么?
1. Module 的 superclass 是什么?

        Object.class       # => Class
        Class.class        # => Class
        Module.superclass  # => Object

Class 的 class 是 Class 自身，这一点有点让人惊讶，但也很好理解，就正如 JavaScript 中 Function 的 `__proto__` 指向 `prototype` 一样。

补充后的全图：

![](../art/ruby-object-inherit-2.png)

##### Method Lookup

一个方法的查找路径，先从对象的 class 中找，没找到，就沿着 class 的 superclass 链找，直到找到为止，如果都没找到，就调用 `method_miss` 方法，默认实现是抛出异常。

用 ancestors 方法查看一个类的 superclass 链：

    MySubClass.ancestors  # => [MySubClass, MyClass, Object, Kernel, BasicObject]

咦，不是说 Object 的 superclass 是 BasicObject 吗?

    Object.superclass  # => BasicObject

怎么中间冒出来一个 Kernel 呢?

Kernel 是 Module，因此我们来看一下，Module 是如何来影响 ancestors 链的。简单地说，如果我们在一个类或 module 中 include 一个 module，那么 Ruby 会把这个 module 插入到 ancestors 链中，而且是插入到该类的上面，如果是 prepend 一个 module，那么这个 module 会插入到 ancestors 链中该类的下面。

例子：

    module M1
      def my_method
        'M1#my_method()'
      end
    end

    class C
      include M1
    end

    class D < C; end

    D.ancestors  # => [D, C, M1, Object, Kernel, BasicObject]

    class C2
      prepend M2
    end

    class D2 < C2; end

    D2.ancestors  # => [D2, M2, C2, Object, Kernel, BasicObject]

如果在 ancestors 链中准备插入某个已存在的 module 时，此次插入操作会被忽略掉。如下例所示：

    module M1; end

    module M2
      include M1
    end

    module M3
      prepend M1
      include M2
    end

    M3.ancestors  # => [M1, M3, M2]

那回过头来说，Kernel 到底是什么，它是一个包括了系统底层 API 的 Module，比如 print：

    Kernel.private_instance_methods.grep(/^pr/)  # => [:printf, :print, :proc]

Object include Kernel，因此 Kernel 出现在了 ancestors 链中 Object 的上面，BasicObject 的下面。

##### Method Execution

当你调用一个方法时，Ruby 做两件事，首先，查找这个方法，然后，执行这个方法。(有点废话的感觉。)

self，指向当前对象，和其它语言中的 this 差不多一样的意思。

正如 JavaScript 中默认所有操作绑定在一个全局对象上，即默认的 this 指向全局对象，Ruby 中也有一个默认的全局对象，它叫 main。

    self        # => main
    self.class  # => Object

有一点比较意外，在 Ruby 中，`class D < C; end`，D 是可以访问 C 中 private 方法的，这和 Java 这种语言不一样。

##### Refinements

为了解决前面说到的，在给已存在的类扩展方法时，会不小心覆盖已存在的方法的问题，从 Ruby 2.0 开始，引用了 Refinements 来解决这个问题 (不知道用的人多不多)。

    module StringExtensions
      refine String do
        def reverse
          'esrever'
        end
      end
    end

    module StringStuff
      using StringExtensions  # 使用时必须显示地使用 using 声明
      'my_string'.reverse  # => 'esrever'
    end

    'my_string'.reverse  # => 'gnirts_ym'

### Chapter 3 - Tuesday: Methods

整个本节的内容，其实都是在教你如何实现一个类似 ActiveRecord 的东西，用元编程来消除大量重复代码，用元编程来动态生成大量方法。

有两种实现方法，一种是动态定义方法，一种是利用 `method_missing` 机制。

#### Dynamic Methods

    ...
    defaults.merge!(options).each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end

2 个关键方法，`send(:method_name, params)` 和 `respond_to?(:method_name)`，使方法可以方便地实现动态调用。

##### Defining Methods Dynamically

动态定义方法，使用 `define_method` 方法。

    class MyClass
      define_method :my_method do |my_arg|
        my_arg * 3
      end
    end

    obj = MyClass.new
    obj.my_method(2)  # => 6

看实际的例子：

    class Computer
      def initialize(computer_id, data_source)
        @id = computer_id
        @data_source = data_source
      end

      def self.define_component(name)
        define_method(name) do
          info = @data_source.send "get_#{name}_info", @id
          price = @data_source.send "get_@{name}_price", @id
          result = "#{name.capitalize}: #{info} (#{price})"
          return "* #{result}" if price >= 100
          result
        end
      end

      define_component :mouse
      define_component :cpu
      define_component :keyboard
    end

上面 `defind_component` 的使用，让我想起了 `attr_reader`、`attr_writer`、`attr_accessor`...

但是，上面这种实现还是不够灵活，现在 `data_source` 只有三种属性，mouse，cpu，keyboard，如果之后它有了新的属性，那我们还要手动加上 `defind_component :new_attr`。能不能根据 `data_source` 的属性动态生成这些方法呢，答案是肯定的：

    class Computer
      def initialize(computer_id, data_source)
        @id = computer_id
        @data_source = data_source
        data_source.methods.grep(/^get_(.*)_info$/) { Computer.define_component $1 }
      end

      def self.define_component(name)
        ...
      end
    end

(我觉得 ActiveRecord 的一部分差不多就是这么实现的，`data_source` 对应的就是 table。)

另外，上例中，还有个 $1 的用法，$1 是个全局变量，用来存储正则表示式中的 matches[1]。

#### method_missing

方法二，使用 `method_missing`。

`method_missing` 是属于 BasicObject 的私有方法，你不能直接调用它，但可以使用 send 方法来调用它。

    class Lawyer; end
    nick = Lawyer.new
    nick.talk_simple  # => NoMethodError: undefined method 'talk_simple' for ...

    nick.send :method_missing, :my_method  # => NoMethodError: undfined method 'my_method' for ...

通过重写 `method_missing` 方法，来将那些重复代码全部移到这里面来处理。

    class Lawyer
      def method_missing(method, *args, &blk)
        puts "You called: #{method}(#{args.join(', )})"
        puts "(You also passed it a block)" if block_given?
      end
    end

    Lawyer.new.talk_simple('a', 'b') { ... }
    # =>
    You called: talk_simple(a, b)
    (You also passed it a block)

文中举了一个 Hashie 库的例子，这个库可以让 Ruby 实现类似 JavaScript 的功能，在 Javascript 中，你可以随时随地地给一个对象加上一个新的成员：

    var counter = {}
    counter.cnt = 5

但 Ruby 默认是做不到。Hashie 是怎么做到的呢，看示例：

    icecream = Hashie::Mash.new
    icecream.flavor = "strawberry"
    icecream.flavor  # => "strawberry"

Hashie 就是借助了 `method_missing` 机制，它重写了 `method_missing` 方法。`icecream.flavor = "strawberry"` 实际上是调用了 icecream 对象的 `flavor=` 方法，这个方法是不存在，因此进入到 Hashie 的 `method_missing` 方法中，在这个方法中，它会把这个 key value 对添加到原生的 Hash 中。当 调用 `flavor` 方法时，则从内部的 Hash 中读值。Hashie 实际是 Hash 的一个包装。

##### Dynamic Proxies

用 `method_missing` 实现一种代理，一种转发。这一小节举了一个 Github 的库 Ghee，内容没有完全看明白，但原理就是一个代理转发。

    class Ghee
      class ResourceProxy
        ...
        def method_missing(message, *args, &blk)
          subject.send(message, *args, &blk)
        end
      end
    end

Ghee 的美妙之处在于，它能自动适应 Github API 的变化，如果 Github API 添加了什么新的属性，Ghee 完全不需要修改任何代码，就能直接访问这个新的属性。

看如何用 `method_missing` 和代理转发和重构 Computer。

    class Computer
      def initialize(computer_id, data_source)
        @id = computer_id
        @data_source = data_source
      end

      def method_missing(name)
        super if !@data_source.respond_to?("get_#{name}_info")
        info = @data_source.send "get_#{name}_info", @id
        price = @data_source.send "get_@{name}_price", @id
        result = "#{name.capitalize}: #{info} (#{price})"
        return "* #{result}" if price >= 100
        result
      end
    end

    comp = Computer.new(42, DS.new)
    comp.cpu  # => "Cpu: 2.9 GHz quad-core ($120)"

代码又简洁了一些。但是，用这种方法，会带来一连串的副作用，后面讲的都是如何解决这些副作用。

##### `respond_to_missing?`

上面展示到，调用 `comp.cpu` 得到了值，因此我们会很理所当然地认为 `comp.respond_to?(:cpu)` 为 true。

    comp.respond_to?(:cpu)  # => false

实际得到了 false，也是可以理解的。那如果我们想在调用 `respond_to?()` 的时候得到预期的 true，该怎么办呢。解决办法是，重写 `respond_to_missing?` 方法：

    class Computer
      ...
      def respond_to_missing?(method, include_private=false)
        @data_source.respond_to?("get_#{method}_info"l) || super
      end
    end

    comp.respond_to?(:cpu)  # => true

##### const_missing

类似 `method_missing`，如果找不到常量，就会进入此方法。和 `method_missing` 不一样的是，`method_missing` 作用在对象上，而 `const_missing` 是作用在全局，它是 Module 的一个方法，因此你需要重写 `Module#const_missing`。

示例略。

#### Quiz: Bug Hunt

要非常小心使用 `method_missing` 引发的无限循环。如果在 `method_missing` 中不小心调用了一个不存在的方法，那么就又会进入 `method_missing`，引发无限循环。

另外，在 `method_missing`，不知道该怎么处理的逻辑，直接抛给 super 处理。

示例略。

#### Blank Slate

`method_missing` 引发的第二个常见问题，Blank Slate。先看例子：

    comp = Computer.new(42, DS.new)
    comp.display  # => nil

`comp.display` 输出了 nil，而不是预期的 "Display..."。原因是 Computer 继承自 Object，Object 中有一个方法就叫 display，因此 `comp.display` 并不会进入 `method_missing` 方法。

解决办法：

1. 让 Computer 直接继承自 BasicObject，而不是 Object
1. 使用 `Module#undef_method` 或 `Module#remove_method` 取消继承而来的 display 方法的定义

#### Dynamic Methods vs. Ghost Methods

两者如何选择。Ghost Methods 强大但是危险，有一些副作用，而且它算是一种 tricky，在 `method_missing` 中响应的方法，并不会出现在 `Object#methods` 中，相比之下，Dynamic Methods 就显得更稳健一些。

所以，选择的原则就是，如果你可以，就选 Dynamic Methods，意思是，如果 Dynamic Methods 可以实现你想要的，就用它没错了，否则，你只能不得不选 Ghost Methods，因为它可以做到 Dynamic Methods 做不到的。
