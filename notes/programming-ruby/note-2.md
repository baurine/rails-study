# Programing Ruby - Note 2

### 第二部分 - Ruby 与其环境

#### 第 14 章 - Ruby 和 Ruby 世界

ruby 的命令行参数：略，太多了，记住几个常用的就行，需要时再翻书。

命令行参数在代码中通过 ARGV 读取。

在代码中通过 ENV 读取环境变量，也可以在代码中往 ENV 中写入值，但只影响当前进程。

其它略。

#### 第 15 章 - 交互式 Ruby Shell (irb)

    $ irb
    2.3.2 :001 > ...

可以在 irb 中 load 一个文件：`load 'code/fib_up_to.rb'`

irb 就是像是 bash shell 一样，在 irb 中再运行 irb，将进入子会话，irb 支持多个、并发的会话，但当前会话只有一个，其余处理休眠状态，使用 `jobs` 命令列出所有 irb 会话，输入 fg 则激活一个特定的会话。

    > irb
    2.3.2 :001 > irb 'haha'
    2.3.2 :001 > jobs
    => #0->irb on main (#<Thread:0x007fa75c87f428>: stop)
    #1->irb#1 on haha (#<Thread:0x007fa75c980110>: running)
    2.3.2 :005 > fg 0
    => #<IRB::Irb: @context=#<IRB::Context:0x007fa75ca0f040>, @signal_status=:IN_EVAL, @scanner=#<RubyLex:0x007fa75ca05658>>
    2.3.2 :002 > jobs
    => #0->irb on main (#<Thread:0x007fa75c87f428>: running)
    #1->irb#1 on haha (#<Thread:0x007fa75c980110>: stop)

子会话与绑定。如果创建子会话时指定了一个对象，如上例中 `irb 'haha'`，它会成为绑定中的 self 值，没有指明接收者的方法会被该对象执行。

    2.3.2 :006 > irb 'test'
    2.3.2 :001 > upcase
    => "TEST"

就像是 bash shell 有相应的配置文件 `.bashrc`，irb 也有，它按以下顺序查找：`~/.irbrc`、`.irbrc`、`irb.rc`、`$irbrc`。此配置文件中放的是 ruby 代码，可以配置 irb shell 的样式等。

扩展 irb。在 irbrc 中定义的方法，可以在 irb 中执行。

irb 的配置选项，略，太多，需要时再看。

irb 的命令，常见的有 exit / conf / jobs / fg / kill ...

配置提示符，用来修改 shell 样式，略。

其它略。

#### 第 16 章 - 文档化 Ruby

RDoc，暂略，等自己写库的时候再看。

#### 第 17 章 - 用 RubyGems 进行包的管理

已了解，暂略，需要发布 Gem 时再回头仔细看。

#### 第 18 章 - Ruby 与 Web

**18.1 编写 CGI 脚本**

了解即可，毕竟太底层了，除非自己写框架，否则你永远都不会用到这部分内容的。

CGI 类提供了编写 cgi 脚本的支持，使用它，你可以更方便的操作表单、cookie、session 和环境等。

erb，在 html 中嵌入 ruby 是非常强大的概念，它基本上提供了同 asp、jsp 或 php 对等的工具。

操作 cookie / session，略。

**18.3 提升性能**

默认的 cgi 脚本，每来一个请求，就会启动一个新的解释器进程，很浪费内存，也使得访问很慢。

对于 apache web 服务器来说，它通过支持加载的模块解决这个问题。一般来说，这些模块是动态加载的，并成为 web 服务器运行进程的一部分，你不必一次又一次地衍生解释器进程来响应请求，web 服务器便是解释器。(大悟！原来如此，以前看 python 的时候，说要借助一个 `mod_python` 的东西，当时是不理解的。) 

`mod_ruby`，它是 apache 的一个模块，将一个完整的 ruby 解释器链接到 apache web 服务器本身。

另外，使用 FastCGI 协议也可以解决部分问题，对所有 cgi 类型的程序都适用，它使用了一个非常简单的代理程序，通常作为 apache 的一个模块，当请求到达时，这个请求会将它们转发到一个特定的、始终运行的进程，它像普通的 CGI 脚本那样进行响应，结果会返回给代理，然后发送回浏览器。(soga，明白了，这就涉及了进程间通信，另外这是不是就是所谓的反向代理，ngnix 是不是可以取代这个东西?)

**18.4 Web 服务器的选择**

除了 apache web 服务器，ruby 1.8 之后捆绑了 WEBrick，一个灵活的、纯 Ruby 的 http 服务器工具。(node 也自带 http 服务器，但 php 印象中一直是需要借助 apache 的)。

**18.5 SOAP 及 Web Services**

SOAP 是一种 RPC，数据传输一般用 XML 格式。它最终实现的效果就是，就像是调用本地的一个方法一样来调用远程服务器上的一个方法。

(终于明白了，但是一直有的疑惑是，为什么不用 rest api 来实现呢? 当问出这个问题，心中又有所明白，rest api 并不适合所有场景，它适合用来表现资源，且多是数据库存储的资源，且 url 的格式有约束，总之局限性比较大，而 SOAP 则没有约束，且它调用的方法并不一定是用来操作数据库的，举个例子，比如把一段文字送到服务器加密再返回来，这个纯粹是内存操作，而且也与资源无关，这个用 rest api 怎么来表达，不好表达嘛，而用 SOAP 表达起来就觉得很顺其自然)。

(其实，这么说起来，SOAP 和 GraphQL 某种形式上也有点相似呢，比如应该都是用 post 请求，传输的数据全部放在 body 里，即没有多个 key-value 对，只是前者是用 xml 来存放数据，后者用类 json 的 graph 语法，在服务端自己解析数据。)

#### 第 19 章 - Ruby Tk

略。这年头还用这玩意来写 UI，那是疯了吧。

#### 第 20 章 - Ruby 和 Windows

略。windows?? bye-bye!

#### 第 21 章 - Ruby 扩展

略，用 C 来扩展 Ruby，高级内容，暂时用不上。

### 第三部分 - Ruby 的核心

#### 第 22 章 - Ruby 语言

这一章是前面内容的温习，查缺补漏。

具体内容略，可作为参考手册查阅。这一章有讲到 block / proc / lambda 的内容，但担心内容已过时，毕竟是 ruby 1.8，现在是 ruby 2.4 了，这部分内容在《Ruby 元编程》看吧。

#### 第 23 章 - Duck Typing

(怎么说呢，这一章在强调动态类型相比静态类型语言的好处，从语言层面上来说，确实没有太多劣势，但抛开语言层面，说到重构，动态语言的重构基本只能靠全文搜索，替换了，全得是非常小心翼翼，这就是一个极大的劣势了，这就是一个最大的非语言因素。所以人们常说，"动态一时爽，重构火葬场"。)

在 Ruby 中，类不是类型，相反，对象类型更多是根据对象能够做什么决定的。在 Ruby 中，它被称为 duck typing。如果对象能够像鸭子那样行走，像鸭子那样呱呱叫的话，那么解释器会很高兴地把它当成鸭子来对待的。

如果你想使用 duck typing 哲学来编写代码，只需要记住一件事情：对象的类型是根据它能够做什么而不是根据它的类决定的。

一个例子，当需要对参数进行检查了，如果你用静态语言的思维习惯来写，你可能会对参数进行类型判断，而如果用 duck typing 思维来写，你会判断参数是否能够响应某些方法，比如：

    def append_song(result, song)
      unelss result.respond_to?(:<<)
        fail TypeError.new("'result' needs '<<' capcability")
      end
      unless song.respond_to?(:artist) && song.respond_to?(:title)
        fail TypeError.new("'song' needs 'artist' and 'title'")
      end

      result << song.title << " " << song.artist
    end

**23.3 转换**

- `to_i` `to_s`
- `to_int` `to_str`
- `to_arr` `to_hash` `to_io` `to_proc` `to_sym`

#### 第 24 章 - 类和对象

这一章算是核心内容之一了，但翻译得并不好。这应该也是《Ruby 元编程》的核心内容。

通篇看下来，Ruby 的类/对象模型和 JavaScript 的原型链有点相似。

与静态语言的不同之一，静态语言，类定义是在编译期处理的：编译期创建符号表，计算出分配多少空间，构造分发表 (dispatch table)，以及其它。而 Ruby，**类和模块的定义是可执行的代码**，虽然是在编译期进行解析，但当遇到定义时，类和模块是在运行时创建的，方法同样也是 (你可以在运行时根据不同条件，创建出不同的方法来)，这可以让你可以比传统语言更动态地构架你的程序。

    module Tracing
      # ...
    end

    class MediaPlayer
      include Tracing if $DEBUG

      # 通过这段代码，体会类、模块、方法的定义是可执行的代码
      if ::EXPORT_VERSION
        def decrypt(stream)
          raise 'Decryption not availabel'
        end
      else
        def decrpty(stream)
          # ...
        end
      end
    end

与静态语言的不同之二，类，比如 String 类，它被对象，比如 `s = "haha"` 的 s 所引用，而它自己也是对象，它是 Class 这个类 (shit，这就是英文原文也会把人绕晕啊) 的对象。

所以可以这么理解，有一个特殊的类叫 Class，其它一切的类 (包括 module) 都是它的对象，比如 String，Object，自定义的类如 `class Guitar` 等。当你在使用 `class Guitar` 这样的语句定义一个类时，正如上面所说的，这部分代码是运行时执行，它实际是在生成一个叫 Guitar 的 Class 对象。

所以，在 Ruby 中，有两种对象，一种是用 `class ClassName` 或 `module ModuleName` 定义的对象，它们是 Class 的对象，所以这些对象都包括以下属性：

- flags：
- super：指向父类对象，比如 String 对象的 super，是指向 Object 对象
- iv_tbl：指向 include 的 module ??
- klass：指向 Class ?? (不对，指向虚拟类，虚拟类里存放了类方法)
- methods：定义的方法，应该是个数组

另一种是通过 Class 对象 new 出来，或者通过字面值赋值的对象，比如：

    lucille = Guitar.new
    s = "hello" # 实际等同于 s = String.new("hello")

这种对象包括以下属性：

- flags：
- iv_tbl：
- klass：被谁 new 出来的，就指向谁，比如上例中，lucille 被 Guitar 对象 new 出来，那 klass 就指向 Guitar 对象

相比 Class 对象，它没有 super 和 methods 属性，也在情理之中。

所以在 Ruby 中，首先通过 `class ClassName` 创建出各种 Class 对象，再通过 Class 对象的 new 方法创建出各种 Class 对象的对象，有种自举的感觉，在 Ruby 中，Class 是火种，是上帝，是起源，不像在静态语言中，一般最基类是 Object，在 Ruby 中，Object 也是 Class 对象。

现在对动态语言的理解有一种耳目一新的感觉，这部分内容也有助于理解 JavaScript 的原型链。

**24.1 类和对象是如何交互的**

部分内容已经总结在上面的。

Ruby 允许创建一个和特定对象绑定的匿名类，有两种写法。

一种是 `class <<obj` 写法：

    a = "hello"
    b = a.dup

    class <<a
      def to_s
        "The value is '#{self}'"
      end
      def two_times
        self + self
      end
    end

    a.to_s       # "The value is 'hello'"
    a.two_times  # "hellohello"
    b.to_s       # hello

 另一种写法，效果和上面是一样的 (这种写法不好，但还是要理解，只是为了看到这种代码时不会懞逼)：

    a = "hello"
    def a.to_s
      "The value is '#{self}'"
    end
    def a.two_times
      self + self
    end

这两种写法的效果都是，生成了一个虚拟类对象，插在了对象 a 和对象 String 之间，原来对象 a 的 klass 指向 String 对象，现在，a 对象的 klass 指向这个虚拟类对象，而这个虚拟类对象的 super 指向 String 对象。(没有图，自己体会一下，真想把书上的图复制粘贴过来，这样一看图就理解了)。

扩展对象，通过 `obj.extend(Module)` 方法来将 module 中的方法添加到对象中，它基本等价于：

    class <<obj
      include Module
    end

但是，如果你在一个类中使用 `extend Module`，那么模块的方法会变成类方法。

Mixin 模块，在类中 include 一个 module 时，模块的实例方法就变成类的实例方法，就好像模块变成了类的超类，这正是它的工作方式。当你包含一个模块时，Ruby 会创建一个指向该模块的匿名代理类，并将这个代理插入到实施包含的类中作为其直接超类，代理类包含有指向模块实例变量和实例方法的引用。(看书上的图，非常形象。疑问，如果一个类 include 了多个 module 呢，这个图会变成怎样? 如果 include 了多个 module，它们会按顺序插入到继承链中)

**24.2 类和模块的定义**

剩余内容不是太明白，暂略。《Ruby 元编程》应该还会讲到。

#### 第 25 章 - Ruby 安全

所有外部数据都是有危险的，不要让它们靠近那些可能改动你的系统的接口。

Ruby 为减少这种危险提供了支持，所有来自外部的数据都可以被标记为**被污染的 (tainted)**，当运行在安全模式下时，传递被污染的对象给一个具有潜在威胁的方法会引发 SecurityError。

其余略。

#### 第 26 章 - 反射，ObjectSpace 和分布式 Ruby

能够内省 (introspect) 是 Ruby 等动态语言的诸多优点之一，那就是在程序内部自己检验程序的方方面面，Java 把这个特性称之为反射 (reflection)，而 Ruby 的内省比 Java 的反射强大很多。

内省可以做到：

- 包括哪些对象
- 类的层次结构
- 对象的属性和方法
- 有关方法的信息

**26.1 看看对象**

遍历当前进程中所有现存对象，使用 `ObjectSpace.each_object` 方法：

    2.3.0 :008 > ObjectSpace.each_object(Numeric) { |x| p x }
    (0+1i)
    9223372036854775807
    279535655170462513955024678816840110169
    NaN
    Infinity
    1.7976931348623157e+308
    2.2250738585072014e-308

查看对象的方法：`obj.methods`

查看对象是否支持某个方法：

    obj.respond_to?("method_name")
    obj.respond_to?(:method_name)

**26.2 考察类**

`superclass` 查看父类，`ancestors` 查看父类和 mixin 的模块。

类似的方法还是 `private_instance_methods`、`class_variables`、`instance_variables`、`constants`，不一而足，用于查看类、模块或对象的方法，变量或常量等。

**26.3 动态地调用方法**

方法一，使用 send 方法

    "Ruby".send(:length) # -> 4
    "Java".send("sub", /Java/, "Ruby") # -> "Ruby"

方法二，使用 method 的 call 方法，类似 c 中的函数指针

    trane = "Ruby".method(:length)
    trane.call # -> 4

方法三，使用 eval 方法

    trane - %q{"Ruby".length}
    eval trane # -> 4

性能，eval 最慢，send 和 method.call 差不多。

**26.4 系统钩子**

即一种 hook 技术。使用 `alias_method` 为原来的方法创建别名，然后重新定义此方法，在此方法中调用原来的方法。如下例所示，为创建的对象增加时间戳。

    class Object
      attr_accessor :timestamp
    end

    class Class  # !! 看，Class 现身了
      alias_method :old_new, :new
      def new(*args)
        result = old_new(*args)
        result.timestamp = Time.now
        result
      end
    end

但是要小心陷入无限循环中。

另外，Ruby 还提供了一些回调方法来跟踪某些事件 (我怎么觉得 Ruby 有点过度设计了呀，有必要搞得这么无所不能吗?)，比如，在添加 module 时会调用 module 的 `method_added` 回调方法。

- `method_added`：添加 module 的实例方法时调用
- `method_removed`：删除 module 的实例方法时调用
- ... 其余略

**26.5 跟踪程序的执行**

- `set_trace_func`
- caller：当前堆栈
- `__FILE__`：当前源文件名

其余略。

**26.6 列集和分布式 Ruby**

列集 (marshaling，第一次听见这种翻译)，其余就相当于 Java 中的序列化和反序列化。用 `Marshal.dump` 进行序列化，用 `Marshal.load` 进行反序列化。如果希望一个类可以被序列化和反序列化，那么需要实现 `marshal_dump` 和 `marshal_load` 方法。

默认 marshal 使用二进制存储，也可以选用其它方式，比如 JSON 和 YAML。YAML 库提供了 `YAML.dump(obj)` 和 `YAML.load(data)` 方法来将对象存储为 YAML 格式和从 YAML 格式中加载对象。`YAML.dump(obj)` 中的这个 obj 必须实现 `to_yaml_properties` 方法。

分布式 Ruby，嗯，就是实现远程调用啦，web 语言都能做，没什么特别。

使用 Ruby 要记住一件重要事情是：Ruby 的 "编译时" 和 "运行时" 几乎没什么区别。

### 第四部分 - Ruby 库

略。
