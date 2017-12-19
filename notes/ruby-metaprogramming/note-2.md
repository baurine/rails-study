# Ruby Metaprogramming - Note 2

### Chapter 4 - Wednesday: Blocks

本章主要讲的是 "callable objects"，它们包括：block / proc / lambda / method。

另外涉及一个语言的重点点：作用域和闭包。

#### The Basics of Blocks

    def my_method(a, b)
      a + yield(a, b)
    end

    my_method(1, 2) { |x, y| (x + y) * 3 }  # => 10

block 必须依附于方法而存在，它紧跟在方法定义之后。在方法中，使用 yield 关键字调用 block，并向它传递参数。

在方法中，可以使用 `Kernel#block_given?` 来判断调用方法时是否提供了 block。

##### 使用 block 实现 C# 中的 using 用法

C# 代码：

    RemoteConnection conn = new RemoteConnection("my_server");
    String stuff = conn.ReadStuff();
    conn.Dispose();

如果在 `conn.ReadStuff()` 时发生异常，conn 将无法正常释放。看 using 用法如何做到：

    RemoteConnection conn = new RemoteConnection("my_server");
    using (conn) {
      String stuff = conn.ReadStuff();
      DoMoreStuff();
    }

无论在 using 后的 `{}` 代码中发生了什么，最后离开 `{}` 的时候，`conn.Dispose()` 都会得到调用。`{}` 中的代码不正像是一个 block 吗?

我们用 Ruby 来实现一个类似的用法，我们叫它为 with (因为 using 已经是关键字了)。

    module Kernel
      def with(resource)
        begin
          yield
        ensure
          resource.dispose
        end
      end
    end

#### Blocks Are Closures

block 可以使变量穿越不同的域 (smuggle variables across scopes)。它可以把外部变量带入方法中 (因此这个变量穿越了作用域)。

代码不能运行在真空中，当它运行时，它需要一个环境，这个环境包括本地变量 (local variables)，实例变量 (instance variables) 等... (这个环境就是所谓的上下文 context)。这些实体 (方法、变量) 绑定在对象上 (最外层的方法绑定在全局对象上)。

block 所绑定的对象，是它在被定义时所处的对象，而不是它被调用时所处的对象。(哇靠，这不是和 ES6 中箭头函数中的 this 一样吗，刚发现。) 怎么来理解，看下面这个例子：

    def my_method
      x = "Goodbye"
      yield("cruel")
    end

    x = "Hello"
    my_method { |y| "#{x}, #{y} world" }  # => "Hello, cruel world"

从输出结果来看，block 中的 x 来自它被定义时所处的上下文中的 x，而不是它被调用时处于在 `my_method` 方法中的 x。

如上例所示中，本来 `my_method` 是有一个单独的作用域的，它是访问不了它外面的作用域的 (这一点和其它语言不太一样)，但通过 block，它访问到了外面作用域中的 x，这就是 block 的作用，跨越作用域，用走私者形容它很形象。

    x = "hello"

    def my_method
      puts x
    end

执行上面的示例，得到错误输出：

    `my_method': undefined local variable or method `x' for main:Object (NameError)

证明在 `my_method` 中无法访问它以外的作用域。

在 block 中定义的 local 变量 (那 instance 变量呢?)，仅在 block 作用域中有效，出了 block 它就无法再被访问。

因为 block 不光只是定义了一些可执行的代码，它还绑定了一个作用域，上下文，很符合闭包的特点，实际 block 就是闭包。

**Scope**

scope，作用域，context，上下文，本地绑定，self ... 相似的作用。

**Changing Scope**

    v1 = 1
    class MyClass
      v2 = 2
      local_variables       # => [:v2]
      def my_method
        v3 = 3
        local_variables     # => [:v3]
      end
      local_variables       # => [:v2]
    end

    obj = MyClass.new
    obj.my_method          # => [:v3]
    obj.my_method          # => [:v3]
    local_variables        # => [:v1, :obj]

在 Ruby 中，定义 class 和 method，都会产生新的作用域，作用域之间的 **local** 变量无法相互访问。这一点和其它很多语言，比如 Java，C# 都很不一样，在 Java / C# 中，在方法中是可以访问方法以外的变量的，但在 Ruby 中是不行的 (上上个例子已经演示了，我刚知道的时候也表示很震惊)。(但我表示疑惑的是，Java / C# 在方法之外或许根本没有所谓的 local 变量吧，在方法以外的都是 instance 变量，或者全局变量)

需要注意的是，作用域是运行时产生的，比如上例中 `my_method`，每次执行此方法，都会产生一个新的作用域，当方法执行结束时，此作用域也就消失了。上例中执行了两次 `my_method` 方法，因此产生了两个不同的相互隔离的作用域。

**Global Variables and Top-Level Instance Variables**

需要强调的是，上面所说的作用域 (scope) 之间无法相互访问的，仅限于 local 变量 (本地变量)，但在 Ruby 中，还有 instance 变量 (实例变量) 和 global 变量 (全局变量)。

定义变量时，前缀为小写字母的是本地变量，为 @ 的是实例变量，为 $ 的是全局变量。

全局变量在所有作用域中皆可访问。

    def a_scope
      $var = 'some value'
    end

    def b_scope
      $var
    end

    a_scope
    b_scope  # => 'some value'

实例变量，在同一个对象中 (即 self 相同的情况下) 可以访问，在最顶层定义的实例变量属于 main object。上例中的全局变量可以用最顶层的实例变量替换：

    @var = 'The top-level @var'

    def my_method
      @var
    end

    my_method  # => 'The top-level @var

**Scope Gates**

三种作用域：

- Class definitions
- Module definitions
- Methods

(貌似 Ruby 和 JavaScript 一样没有块作用域。但因为 Ruby 有本地变量和模块管理，所以没有 js 中方法之外的变量会污染全局的问题，当然，现在 es6 终于有了块作用域和模块管理。)

**Flatten the Scope**

通过借助 block 来实现。因为 block 是依附于方法调用，因此也相当于是借助使用 block 的方法调用。具体来说，对应上面三种作用域：

- 用 Class.new do ... end 替代 Class definition
- 用 define_method do ... end 替代 Method definition

例子：

    my_var = "Success"

    MyClass = Class.new do
      puts "#{my_var} in the class definition"

      def my_method
        # TODO
        # How can we print print it here?
      end
    end

在上例中，我们成功地在 class 定义中访问到了 class 之外作用域中的本地变量。那如何进一步在方法定义中也能访问到 `my_var`，解决办法是继续用 block，用 `define_method :my_method` 调用替代 `def my_method`：

    my_var = "Success"

    MyClass = Class.new do
      puts "#{my_var} in the class definition"

      defined_method :my_method do
        puts "#{my_var} in the method"
      end
    end

这种技术称为 Flat Scope。

**Sharing the Scope**

利用 Flat Scope 技术做一些事情，比如共享一些变量，同时用 Scope Gate 保护它们不被外界所访问：

    def define_methods
      shared = 0

      Kernel.send :define_method, :counter do
        shared
      end

      kernel.send :define_method, :inc do |x|
        shared += x
      end
    end

    define_methods
    counter  # => 0
    inc(4)
    counter  # => 4

**Closures Wrap-up**

每个 Ruby 的作用域都包含一堆单独的绑定，每个作用域都被 Scope Gate 隔离：class，module，def。

#### instance_eval()

另一种随心所欲地混合代码和绑定的方法。

    class MyClass
      def initialize
        @v = 1
      end
    end

    obj = MyClass.new

    obj.instance_eval do
      self  # => #<MyClass:0x... @v=1>
      @v    # => 1
    end

    v = 2
    obj.instance_eval { @v = v }
    obj.instance_eval { @v }  # => 2

从上面可以看出，在一个对象的 `instance_eval` 方法调用中的 block 中，即可以访问到对象内的 class 作用域，又可以访问到 Top-Level 作用域，block 中 self 指向对象自身 (而不是默认的当前作用域所绑定在的对象上，比如上例中 block 中默认的 self 本应该是 main object)。

对象的 `instance_eval` 方法中的 block，就像是一根探针，用来查看自身内部的情况。这个 block 被称为 Context Probe。

**Breaking Encapsulation**

`instance_eval` 破坏了封装，它可以直接访问一个对象的内部实例变量，从上例中可以看到，在 `instance_eval` 中直接访问甚至修改了 obj 的实例变量 `@v` 的值。

但这也是 `instance_eval` 能带来的好处，如果有一个对象，它的某个实例变量没有对外提供访问接口，而我们又确实需要修改这个变量的值，那么就可以毫不犹豫地使用 `instance_eval` 方法。书中举的例子，开启和关闭 logger：

    should "allow turning on static assets logging" do
      Padrino.logger.instance_eval { @log_static = true }
      # ...
      get "/images/something"
      assert_equal "Foo", body
      Padrino.logger.instance_eval { @log_static = false }
    end

**instance_exec()**

相比 `instance_eval`，`instance_exec` 支持传参。使用场景，看例子：

    class C
      def initialize
        @x = 1
      end
    end

    class D
      def twisted_method
        @y = 2
        C.new.instance_eval { "@x: #{@x}, @y: #{@y}" }
      end
    end

    D.new.twisted_method  # => "@x: 1, @y: "

`C.new.instance_eval` 中，可以访问到 C 的实例变量，很自然，因为 self 指向 C 实例对象，它也可以访问得到 `twisted_method` 中的本地变量，但是它访问不到 D 类中的实例变量，因为实例变量是靠 self 来访问的。

解决办法，使用 `instance_exex()` 将 @y 作为参数传入 block 中：

    class D
      def twisted_method
        @y = 2
        C.new.instance_exec(@y) { |y| "@x: #{@x}, @y: #{y}" }
      end
    end

**Clean Rooms**

一种类，主要用来执行 `instance_eval`，在 `instance_eval` 中执行一些逻辑，类内部自身没有太多逻辑。

#### Callable Objects

四种：

- block
- proc
- lambda
- method

Ruby 中几乎所有的都是对象，除了 block。这导致了 block 的一个很大的缺点，无法复用。为了解决这个问题，Ruby 提供了两种方式来将 block 转成 (或者说包装成) 可复用的对象，一种是 proc，一种是 lambda，它们很相似，两种方式生成的对象都是 Proc 类型，但有细微差别。

- proc
- lambda

**Proc**

使用 proc 的方式将 block 转成 Proc 对象：

    inc = Proc.new { |x| x + 1 }
    inc.class  # => Proc
    inc.call(2)  # => 3

这种技术被称为 Deferred Evaluation (延迟估值，为什么呢?? 这和普通的方法调用有什么区别?)。

使用 lambda 的方式将 block 转成 Proc 对象：

    dec = lambda { |x| x - 1 }
    dec.class  # => Proc
    dec.call(2)  # => 1

lambda 的另外一种写法，有参时：

    dec = ->(x) { x + 1 }

无参时：

    p = -> { puts "lambda" }

用 Proc#call 方法来执行 block 中的代码。( call，apply，... 又想起了 JavaScript )

**The & Operator**

block 就像是一个附加到某个方法的匿名参数。在方法内部用统一用 yield 来执行它 (因为 block 才可以匿名啊)。但在是某些情况下，我们需要这个 block 有名字，比如作为参数传递给另一个方法。使用 & 操作符来实现具名的 block。

示例：

    def math(a, b)
      yield(a, b)
    end

    def do_math(a, b, &operation)
      math(a, b, &operation)
    end

    do_math(2, 3) { |x, y| x * y }  # => 6

实际内部是怎么运作的呢，实际 Ruby 先把 block 包装成了 Proc 对象，然后对 Proc 对象使用 & 操作符，就可以取到原始的 block。如果要把具名的 block 转换回 Proc 对象，直接把 & 操作符去掉就行了。

    def my_method(&the_proc)
      the_proc
    end

    p = my_method { |name| "Hello, #{name}" }
    p.class  # => Proc
    p.call("Bill")  # => "Hello, Bill"

总结：对 Proc 对象使用 & 操作符，将得到 block。

**Procs vs. Lambdas**

用 lambda 方式生成的 Proc 被称为 lambdas，而其它方式生成的 Proc 就是简单地称为 procs。可以用 Proc#lambda? 方法来判断一个 Proc 对象是不是 lambda。(为什么不干脆生成一种叫 Lambda 类型的对象? 因为它们功能基本相近，只有细微区别?)

- Proc 和 Lambda 的区别之一，return 的处理。

lambda 中的 return 语句，只会从 lambda 中退出，而 proc 中的 return，会从 proc 定义时所处的作用域退出。解决办法是在 proc 定义中不要显式地使用 return。(但是我们也可以利用这种特性提前中断方法的执行)

- 区别之二，对参数的校验严格性

如果传了错误参数给 lambda，会提示 ArgumentError 并失败，对于 proc 来说，多的参数会被抛弃，少的参数会被置 nil。

结论：优先使用 lambda，除非你想使用 proc 的 return 来提前中断执行逻辑，或是参数有特别需求。

**Method Objects**

method 也是对象，也可以通过 call 来执行，那怎么取到方法对象呢，通过 `object.method` 方法，示例：

    class MyClass
      def initialize(x)
        @x = x
      end
      def my_method
        @x
      end
    end

    object = MyClass.new(1)
    m = object.method :my_method
    m.call  # => 1

**Unbound Methods**

UnboundMethods 是一种脱离了原来类或 module 的方法，(就像是脱离了原来宿主的生物，变得无家可归，游离在外面)。你不能再对 UnboundMethod 执行 call 操作，除非你把它重新和某个对象进行 bind 后才可以。UnboundMethod 也可以用来定义方法。

示例：

    module MyModule
      def my_method
        42
      end
    end

    unbound = MyModule.instance_method(:my_method)
    unbound.class  # => UnboundMethod
    unbound.call  # => NoMethodError

    String.send :define_method, :another_method, unbound
    "abc".another_method  # => 42

UnboundMethod 的应用，举了个例子，没看懂，暂略过。

#### Writing a Domain-Specific Language (DSL)

(什么是 DSL? 制定规则?)

附录 2 有一些解释说明，大致是说，是一种用于专门用途的语言，很像是一种特定格式的配置文件，比如 Makefile，用于使用 Ant 来构建 Java 项目的 xml 配置文件，如今的 Gradle 配置文件。

与 DSL 相对应的是 GPL (General Programming Language)。

DSL 大致分两种：

- external DSL，就像是上面举的例子，这些 DSL 定义在 GPL 之外，有一个专门的程序来解析它，比如解析 Makefile 的 make，Ant。
- internal DSL，DSL 在 GPL 内部定义，执行。典型的 Ruby 就是这样，DSL 直接用 Ruby 定义，运行。我觉得类似的还有 Gradle。

我暂时把 DSL 理解成制定某种规则的语言。

一个最简单的示例：

    # redflag.rb
    # 定义
    def event(desc)
      puts "ALERT: #{desc}" if yield
    end
    load 'events.rb'

    # events.rb
    # 执行
    event "an event that always happens" do
      true
    end

    event "an event that never happens" do
      false
    end

执行 redflag.rb 后得到下面的输出：

    ALERT: an event that always happens

随后我们给这个例子添砖加瓦，最后你会发现和一些测试框架就很相似了。

演进后比较让人容易理解的一个版本，加入了 setup 用来设置共享的变量：

    # redflag.rb
    def setup(&block)
      @setups << block
    end

    def event(desc, &block)
      @events << { desc: desc, condition: block }
    end

    @setups = []
    @events = []
    load "events.rb"

    @events.each do |event|
      @setups.each do |setup|
        setup.call
      end
      puts "ALERT: #{event[:desc]}" if event[:condition].call
    end

    # events.rb
    setup do
      puts "Setting up sky"
      @sky_height = 100
    end

    setup do
      puts "Setting up mountains"
      @mountains_height = 200
    end

    event "the sky is falling" do
      @sky_height < 300
    end

    ...

上面的例子定义了 Top-Level 的实例变量 (@setups，@events)，不是很好，如何来消除它们。书中的例子选择了用一个立即执行的 lambda 来包裹这个顶层变量。(有点像在 JavaScript 中使用 IIFE 来包裹一堆逻辑以避免变量污染全局。) 同时用了 Kernel 级 `define_method` 来定义顶层的一些方法，如 setup，event ... 看代码：

    # redflag.rb
    lambda {
      setups = []
      events = []

      Kernel.send :define_method, :setup do |&block|
        setups << block
      end

      Kernel.send :define_method, :event do |description, &block|
        events << { description: description, condition: block }
      end

      Kernel.send :define_method, :each_setup do |&block|
        setups.each do |setup|
          block.call setup  # 等于 yield(setup)
        end
      end
      # 这个地方绕得有点深，我觉得是多此一举，我觉得可以这样实现：
      # Kernel.send :define_method, :each_setup do
      #   setups.each do |setup|
      #     setup.call
      #   end
      # end
      # 在外面执行时，只需要执行
      # each_setup

      # 同理上面
      Kernel.send :define_method, :each_event do |&block|
        events.each do |event|
          block.call event
        end
      end
    }.call

    load 'events.rb'

    each_event do |event|
      each_setup do |setup|
        setup.call
      end
      puts "ALERT: #{event[:description]}" if event[:condition].call
    end

...好绕好绕啊，看了好几遍，终于理解了 `each_setup` 和 `each_event` 的逻辑，两者逻辑是一样，这里只分析前者。(实际我认为这里的实现是把简单问题复杂化了)

首先，`each_setup` 的定义等效于下面：

    def each_setup
      setups.each { |setup| yield(setup) }
    end

然后，在使用 `each_setup` 方法时，后面的 block 将接收 setup 作为参数，而且这个参数是一个 Proc 对象，因此可以对它执行 call 操作。因此，下面的代码就很理所当然了：

    each_setup do |setup|
      setup.call
    end

关键在于，上面代码中如果能理解 `block.call setup` 实际是等于 `yield(setup)` 一切就恍然大悟了。

**Adding a Clean Room**

我们更进一步。前面的例子中，不同的 event 之间，它们绑定在同一个对象上，共享是相同的实例变量，它们可以相互修改相同的实例变量，因此可能影响对方的逻辑。我们能不能让每一个 event 的操作都在单独的对象上呢。这时候 `instance_eval` 就要出马了。

    # redflag.rb
    each_event do |event|
      env = Object.new
      each_setup do |setup|
        env.instance_eval &setup  # 对 Proc 对象进行 & 操作，将得到 block
      end
      puts "ALERT: #{event[:description]}" if env.instance_eval &(event[:condition])
    end
