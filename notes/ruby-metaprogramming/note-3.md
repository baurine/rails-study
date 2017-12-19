# Ruby Metaprogramming - Note 3

### Chapter 5 - Thursday: Class Definition

正如前面所言，Ruby 中的 class 是有一些特殊的，当你在定义一个类时，实际上它是在生成一个 Class 的对象。

#### Class Definitions Demystified

de-mystify 解密。

**Inside Class Definitions**

可以在 class 中放置任何代码，不光是定义方法。方法以外的语句会立即执行。另外，类的定义 (实际是执行) 还有返回值，返回值是最后一个 statement 产生的值。

    result = class MyClass
      puts 'hello'
      42
    end

    # 输出
    hello
    => 42

另外，对于 Ruby 的 class，还有很重要的一点，self 的值，先来看示例代码：

    class MyClass
      puts self

      def self_in_method
        puts self
      end
    end

    # 输出结果
    MyClass  # MyClass 中的 self

    > obj = MyClass.new
    > obj.self_in_method
    #<MyClass:0x007f89bf982510>

可以看出，类定义中的 self 和类中的方法中的 self 是不一样的。类中的 self，指向的 Class 对象，即上例中的 MyClass 这个常量对象，而方法中的 self，是指向 MyClass 类的实例对象，切记!

**The Current Class**

当使用 class 打开一个类时，self 将指向这个类对象，在其中定义的方法将属于这个类。如果现在要动态地给一些类扩展方法，并不知道这些类的名字，该怎么办，我们需要一根探针，能够深入到这些类的内部，联想到我们前面讲过的 `instance_eval` 有类似的作用，因此，对于 class 来说，有 `class_eval` 可以帮助来实现。

    def add_method_to(a_class)
      a_class.class_eval do
        def m; 'Hello!'; end
      end
    end

    add_method_to String
    "abc".m  # => 'Hello!"

疑惑，用 `String.send :define_method, :m do ... end` 做不到吗? 试了一下，可以的呀。

    String.send :define_method, :m do
      'hello'
    end

    "abc".m  # => 'hello'

和 `instance_eval` 的区别，`instance_eval` 只改变 self，而 `class_eval` 不仅改变 self，还改变当前类 (current class)。

- 对于类来说，如果你要给类新增方法，就用 `class_eval`，不然用 `instance_eval` 就够了 (比如新增一个类的实例变量，后面会说到)。
- 对于普通的对象来说，只有选择 `instance_eval` 了，因为 `calss_eval` 只作用在类对象上 (注意不是类的实例对象)。

下面的代码效果是一样的：

    class MyClass
      def self.read
        @x
      end
    end

    MyClass.instance_eval { @x = 1 }
    MyClass.class_eval { @x = 1 }

`class_eval` 比 `class` 灵活，如上所示，`class_eval` 不需要一个常量来做为类名，但 `class` 却需要。另外 `class_eval` 使用 block 实现，因此它可以穿越作用域，而 `class` 不行。

在类的定义中，self 和 current class 是一个值，但在方法定义中，两者是不相等的。

**Class Instance Variables**

这里 Ruby 又整出一个概念来，叫类的实例变量，注意，并不是对象的实例变量... (shit! Ruby 就是概念太多了，Python 肯定比这简单很多)。

类的实例变量，其实就是其它语言中类的静态变量啦，但定义方式和类实例对象的实例变量一样，容易让人搞混，看下面的示例代码：

    class MyClass
      @my_var = 1

      def self.read
        @my_var
      end

      def write
        @my_var = 2
      end

      def read
        @my_var
      end
    end

    obj = MyClass.new
    obj.read  # => nil
    obj.write
    obj.read  # => 2
    MyClass.read  # => 1

总结一下就是：

- 在类中 (或者说是 class scope) 定义的以 @ 为前缀的变量为类的实例变量，只能在静态方法中访问，它属于类这个对象自身。
- 在方法中 (或者说是 method scope) 定义的以 @ 为前缀的变量为类的实例对象的实例变量，它属于类的实例对象。

与传统语言 (Java) 中静态变量的区别：

- Java 中的静态变量，在类的实例方法和静态方法中都可以访问到，但在 Ruby 中，只有静态方法 (其实 Ruby 并没有静态方法一说，只能说是类似) 可以访问到。
- Java 中的静态变量，可以继承给子类，但 Ruby 不行，因为本质上，Ruby 中类的实例变量是属于这个类对象自身的。

后面又介绍了 Ruby 中的类变量 (shit again! Ruby 真心是把自己搞复杂了)，用 @@ 作为前缀，可以被继承和在类实例方法中访问，更接近 Java 中的静态变量，但还是有不少坑，弃用。

**类的实例变量的应用**

举了一个测试的例子，很有意思，详情略。

#### Quiz: Class Taboo

(为什么这部分内容能成为独立的一小节?)

不准用 class 关键字，实现和下面功能相同的代码：

    class MyClass < Array
      def my_method
        'hello'
      end
    end

不就是用 Class.new 来替代 class 吗，前面说过了呀：

    c = Class.new(Array) do
      def my_method
        'hello'
      end
    end

#### Singleton Methods

Ruby 有一种很神奇的功能啊，可以给一个单独的对象添加方法。(写完这句话我就想到，完全不神奇啊，这不就是 JavaScript 中最普通的功能吗?)

    str = "just a regular string"

    def str.title?
      self.upcase == self
    end

    str.title?  # => false
    str.methods.grep(/title?/)  # => [:title?]
    str.singleton_methods  # => [:title?]

JavaScript:

    var obj = {
      text: 'haha'
    }
    obj.title = function() {
      return this.text.toUpperCase() === this.text
    }
    obj.title()  # => false

(试验了，如果 obj 如果是一个字符串，是不可以对它增加方法的，obj 必须是 Object 类型)

Ruby 又给它取了个名字，叫 单例方法 (实际和设计模式中的单例毛关系都没有...)

再稍微引申一下，这个 Singleton Method 就会变得神奇起来。上例中 str 对象，如果换成类对象 (不会类的实例对象哦) 会怎么样，比如 MyClass，因为它也是对象，我们也可以给它添加方法。我们又知道，在类的定义中 (不是方法定义中)，self 就是指向这个类对象的，那么就形成这样的语句：

    class MyClass
      def self.title?
        # ...
      end
    end

这不就类似其它语言中的静态方法吗?

其实，说真的，对于 Ruby 来说，只要理解了 MyClass 也是一个对象，其它的一切概念都非常好理解，不然的话，就会各种疑惑。这可以说是 Ruby 的实现的核心，基础。

`MyClass.title?` 看似调用一个静态方法，但实际也是调用一个对象的方法，一个常量对象的方法，和调用普通类的实例对象没有区别。这是一种形式的统一。

**Class Macros**

举例 `attr_accessor()` 的实例，它是 Singleton Method，所以它可以在类中，方法外被调用。类似 `define_method` 也是 Singleton Method。

Ruby 的对象没有属性一说，和其它语言不一样。外界无法直接访问到对象内部的实例变量，必须通过方法。

然后，还讲了一种技术，如何友好地提示一些 API 过期了，自然用新 API 替换旧的 API，nice!

    def self.deprecated(old_method, new_method)
      define_method(old_method) do |*args, &block|
        warn "Warning: #{old_method}() is deprecated, Use #{new_method}()."
        send(new_method, *args, &block)
      end
    end

    deprecated :GetTitle, :title
    # ...

也是一种 Hook 思想。

#### Singleton Classes

问题的引出：如果给一个单独的对象添加了方法，或是给一个类对象添加了方法，这些方法存储在方例链的哪个地方?

    class MyClass
      def my_method; end
    end

    obj = MyClass.new
    obj.my_method

    def obj.my_singleton_method; end  # my_singleton_method 存储在哪个对象中

    def MyClass.my_class_method; end  # my_class_method 存储在哪个对象中

当我们重新拿出以前绘制的那张对象继承关系图来看，发现这两个方法哪都存不了。(obj 不能存储方法，因为它不是 class)

![](../art/ruby-object-inherit-2.png)

答案就是，它们存储在一个隐藏类对象中，这个类对象就是 Singleton Class。

一个对象 (包括普通对象和类对象) 可以拥有一个自己的特别的、隐藏的类，被称为这个对象的 singleton class (你可以理解成是 meta class 或是 aigenclass)。

Ruby 提供了一种语法来进入到对象的这个被隐藏的类内部：

    class << an_object
      # your code
    end

    obj = Object.new
    singleton_class = class << obj
      self
    end
    singleton_class  # => #<Class:#<Object:0x007fb20116f368>>

或者直接通过对象的 `singleton_class` 方法得到这个类对象：

    "abc".singleton_class  # => #<Class:#<String:0x007fb201155e90>>

**Method Lookup Revisited**

再论方法查找链。来看看有了 singleton class 后是长什么样。

记住这张图即可：

![](../art/ruby-singleton-classes-inheritance.png)

    obj.class  # => D
    obj.singleton_class.super_class  # => D

    D.super_class  # => C
    D.singleton_class.super_class  # => #C

从此图上可以看出，Singleton Method 是可以继承的 (Java 这些语言是不可以的...)

**Class Method Syntaxes**

Class Method 和 Singleton Method 是相同的意思 (会不会是我一直理解错了，后者是专门指添加在普通对象上的方法)。三种定义方式：

    def MyClass.a_class_method; end

    class MyClass
      def self.a_class_method; end
    end

    class MyClass
      class << self
        def a_class_method; end
      end
    end

**Singleton Classes and instance_eval()**

前面说到 `class_eval` 改变了 self 和 current class，而 `instance_eval` 只改变了 self，因此我们可以在 `class_eval` 中为类扩展方法，但在 `instance_eval` 中只能改变实例变量。

但实际上，`instance_eval` 也改变了 current class，它将指向对象的 singleton class，因此我们可以在 `instance_eval` 中为普通对象扩展 singleton method。

例子：

    s1 = "abc"
    s1.instance_eval do
      # 此时 self 指向 s1
      # current class 指向 s1 的 singleton class
      def swoosh!; reverse; end
    end
    s1.swoosh!  # => "cba"

上面的代码等效于：

    def s1.swoosh!; reverse; end

**Class Attributes**

看 singleton class 的应用。前面说到 `attr_accessor` 的使用，它在类中是用来给类的实例对象定义实例变量的，如果我们想给这个类对象自身添加实例对象呢，要把定义到类的 singleton class 中。

示例：

    class MyClass
      attr_accessor :a
    end

    obj = MyClass.new
    obj.a = 2
    obj.a  # => 2

    class MyClass
      class << self
        attr_accessor :b
      end
    end

    MyClass.b = 3
    MyClass.b  # => 3

#### Quiz: Module Trouble

在 class 中 include module。

- 如果直接在 class 中 include module，module 中的方法将成为 class 的实例对象的方法
- 如果在 class 或任意对象的 singleton class 中 include module，module 的方法将 class 或对象的 singleton method。也可以用 extend module 来简化这种用法。

示例：

    module MyModule
      def my_method; 'hello'; end
    end

    class MyClass
      class << self
        include MyModule
      end
    end

    MyClass.my_method  # => "hello"

    obj = Object.new
    class << obj
      include MyModule
    end
    obj.my_method  # => "hello"
    obj.singleton_methods  # => [:my_method]

用 extend 简化，等效于下面的代码：

    obj.extend MyModule
    obj.my_method  # => "hello"

    class MyClass
      extend MyModule
    end
    MyClass.my_method  # => "hello"

#### Method Wrappers

学习三种用一个方法来包裹另一个方法的方式。

要解决的问题：有一个方法，到处都被使用了，但这个方法有一些错误，内部没有处理，这个方法是库方法，我们无法直接修改，我们需要对这个方法做一个封装，来处理这些错误，然后将原来直接调用这个方法的地方无缝地迁移到这个新方法上来。(也算是一种 Hook 思想吧，Hook 无处不在。)

**方法一：Around Aliases**

使用 `Module#alias_method` 方法。

第一个例子差点就把我搞晕了：

    class String
      # 当执行此处时，:lenght 方法还没有被重写，因此它还指向原来默认的 :length 实现，我们可以理解成 :real_lenght = super.length (实际 :length 并不在 super 中)
      alias_method :real_length, :length

      # 当执行到此处时，:length 被重写，但 :real_length 还是指向原来默认的实现
      def length
        # 这句相当于 super.length > 5 ? 'long' : 'short'
        real_length > 5 ? 'long' : 'short'
      end
    end

    "War and Peace".length  # => "long" (执行新的 :length 方法)
    "War and Peace".real_length # => 13  (执行原来默认的 :length 方法)

**方法二：Refine and super**

    module StringRefinement
      refine String do
        def length
          # 在 refine 中 super 指的是原来默认的 :length 方式，并不一定是父类中的方法
          super > 5 ? 'long' : 'short'
        end
      end
    end

**方法三：Module#prepend**

前面我们讲到，include 一个 module，是把 module 插到类的继承链的顶部，而 prepend 一个 module 是把 module 插到类的继承链的底部，这样可以使这个 module 中方法优先被访问到。这应该是最简单快捷的方式了。

    module ExplicitString
      def length
        super > 5 ? 'long' : 'short'
      end
    end

    String.class_eval do
      prepend ExplicitString
    end

    "War and Peace".length  # => "long"

#### Wrap-Up

Ruby 的对象模型到这就差不多讲完了。
