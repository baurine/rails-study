# Programing Ruby - Note 1

Note for *Programming Ruby* Book (second version).

2016/8/1，花了半天读完了《Programming Ruby》第2版，是以 Ruby 1.8 版为例讲解的。

因为有了 c/c++/java/swift/js/python 等语言的基础，理解起来就快多了。也从 ruby 中领悟了其它语言的一些设计，比如，从 ruby 的 block 中领悟了 js 中用 yield 实现 generator，也可以说和协程很相似。

前段时间看了 swift，可以看出，swift 和 ruby 也是很多相通之处的。

语言之间是可以融汇贯通的。

ruby 语言的特性：

1. 动态语言，和 js/python 一样，定义变量时不需要指定类型，实际变量的类型在运行是可以变化的，不是强类型。
1. 强大的 block。
1. 方法调用可以不用加括号。

我是如何理解 ruby 中的符号，symbol。其实可以把它理解为枚举值，全局的枚举值，也可以理解为类似指针。他们的特点是程序运行期间全局唯一，可以把它的值想像成是内存地址，内存地址是不会冲突的。

ruby 没有 interface，只有比 interface 更强大的 module 与 mixin 机制 (python 也没有，js 也没有，动态语言是不是都缺这个?? interface 和 多态是强类型语言的特性，而动态语言因为依靠鸭子类型而不需要 interface 和多态)。

ruby 的 module 相当于有逻辑实现的 interface，类使用 include 关键字将 module 包含进来，相当于 java 中的 implement。ruby 的类还可以 extend module，表示包含进来的 module 方法是作为该类的类方法，而不是实例方法。

ruby 的 module 的另一个作用是生成命名空间。

2017/5/31 重新阅读。不会是很仔细的阅读，已经熟悉的就跳过。这本书应该是一本案头书。

### 第一部分 - Ruby 面面观

#### 第 1 章 - 入门

ruby 安装，略。

#### 第 2 章 - Ruby.new

ruby 基本知识。

`$name` 全局变量，`@name` 实例变量，`@@name` 类变量。

方法名可以以 `?` `!` `=` 结尾。(这是与一般语言不同的地方)

`@w{ant bee cat dog elk}` -> `['ant', 'bee', 'cat', 'dog', 'elk']`，生成数组的便捷方法。

控制结构，略。

正则表达式，`=~`，`match()`，`sub()`，`gsub()`。`sub` 表示替换第一个匹配的值，`gsub` 表示替换所有匹配的值。

    line.gsub(/Perl|Python/, 'Ruby')

Block 和迭代器，略。

读/写文件，通过 `gets` 函数从标准输入流中读取下一行。

    line = gets
    puts line

#### 第 3 章 - 类、对象和变量

没有很特别的内容，大部分内容略。

类变量必须显式地初始化。

单例的写法：

    class MyLogger
      private_class_method :new
      @@logger = nil
      def self.create
        @@logger = new unless @@logger
        @@logger
      end
    end

使用 `private_class_method` 将 new 方法标记为 private。只允许通过 create 类方法创建对象。

变量保存对象引用。

#### 第 4 章 - 容器、Blocks 和迭代器

Ruby 中的容器主要两大类：数组 Array 和散列表 Hash。

数组：支持负数索引，支持 range 索引。

    a = [1, 3, 5, 7, 9]
    a[-1]      -> 9
    a[1, 3]    -> [3, 5, 7]
    a[2..3]    -> [5, 7, 9]
    a[2...3]   -> [5, 7]

散列，略。

实现一个 SongList 容器，略。

Blocks 可以作为闭包，它包括了定义 block 时的上下文。

容器、block 和迭代器是 Ruby 的核心概念。

#### 第 5 章 - 标准类型

数字、字符串、区间、正则表达式。

数字：整数 (Fixnum/Bignum)，浮点数。

字符串：单引号，双引号。

操作字符串：String 的一些方法，split，chomp，squeeze，scan ...

区间：Range，就是一种数据类型，支持这种类型的现代语言越来越多了，比如 swift。

区间作为序列：`1..10`，`'a'..'z'`，`0...3`。

区间作为条件，这个很神奇啊：

    while line = gets
      puts line if line =~ /start/ .. line =~ /end/
    end

这段代码将打印从标准输入得到的行的集合，每组的第一行包含 start 这个词，最后一行包含 end 这个词。

当区间作为条件的逻辑是这样的，当区间的第一部分的条件为 true 时，它们就打开，当区间的第二部分的条件为 true 时，它们就关闭。

区间作为间隔：

    (1..10) === 5  -> true

**正则表达式**

暂略，回头再用到时回来补充。

#### 第 6 章 - 关于方法的更多细节

可变长度的参数列表：在最后一个参数前加一个 `*` 号即可，内部这些参数将被 array 接收。

最后一个参数如果前缀为 `&`，那么所关联的 block 会被转换成一个 Proc 对象，然后赋值给这个参数。这样做的目的在于，proc 对象可以保存起来在将来使用。

#### 第 7 章 - 表达式

Ruby 和其它语言的一个不同之处就是任何东西都能返回一个值，几乎所有的东西都是表达式。

Ruby 中的许多运算符是由方法调用来实现的，比如 `a*b+c`，等价于 `(a.*(b)).+(c)`

用反引号包围或 %x 为前缀的字符串，会被作为底层 shell 命令执行并返回，返回值就是该命令的标准输出，命令的退出状态保存在全局变量 `$?` 中。

    2.3.0 :001 > `date`
     => "Wed May 31 16:25:02 CST 2017\n"

Ruby 的赋值有 2 种基本形式。第一种是将一个对象引用赋值给变量或常量，这种形式的赋值在 Ruby 中是直接执行的 (hardwired)。

    instrument = "piano"

第二种形式，等号左边是对象属性或者元素的引用。

    song.duration = 234
    instrument["ano"] = "ccolo"

这种形式实际是通过调用左值的方法来实现的，这意味着你可以重载它们。

    class Song
      def duration=(new_val) # 第二种形式的赋值方法
        @duration = new_val  # 第一种形式的赋值方法
      end
    end

并行赋值：

    a, b = b, a

**7.4 条件执行**

布尔表达式。Ruby 对真值的定义很简单，任何不是 nil 或 false 的值都为真，数字 0 也是真，这和一般语言不一样，因为 0 在 ruby 中也是一个真实存在的对象。

`defined?()` 方法，判断参数是否定义，如果定义，返回对参数的描述，否则返回 nil。

if / unless

**7.5 case 表达式**

case 支持各种匹配：数字，字符串，正则，区间，类的继承关系 ...

**7.6 循环**

循环，迭代器。break / redo / next，retry。

**7.7 变量作用域、循环和 Blocks**

while / until / for 内建到了 ruby 语言中，但没有引入新的作用域：前面已存在的局部变量可以在循环中使用，而循环中新创建的局部变量也可以在循环后使用。(原来如此，我之前就一直在想，为什么我在 if/else 中定义的变量，出了 if/else 之后为什么还能用。这个和 java/c/c++ 还是不一样，在 c 中，用 `{}` 包围起来的一段代码就是一个单独的作用域)

被迭代器使用的 block，在这些 block 中创建的局部变量，外部无法访问，而 block 可以访问在 block 外部创建的局部变量。

#### 第 8 章 - 异常、捕获和抛出

begin...rescue...else...ensure...end

catch...throw

raise

#### 第 9 章 - 模块 (Module)

模块是一种将方法、类和常量组织在一起的方式，它提供两个主要的好处：

1. 模块提供了命名空间来防止命名冲突
1. 模块实现了 mixin 功能

module 中的实例变量与 class 中的实例变量有冲突的风险。

包含其它文件：load / require，前者每次 load 时都重新加载，而后者多次 require，实际只加载一次。

#### 第 10 章 - 基本输入与输出

Ruby 提供了两套操作 IO 的接口：

1. Kernel 模块，相关方法：gets / open / print / printf / putc / puts / readline / readlines ...
1. IO 对象，基类 IO 类，子类有 File 类，BasicSocket 类 ...

**10.2 文件打开和关闭**

    File.open("testfile", "r") do |file|
      # ...
    end

block 退出时，file 会自动关闭。

**10.3 文件读写**

Kernel 模块中定义的方法基本都可以用于 IO 对象：

    File.open("testfile") do |file|
      while line = file.gets
        puts line
      end
    end

但 IO 对象还有一组额外的访问方法，使用起来更简单，即迭代器：

    File.open("testfile") do |file|
      file.each_line("e") { |line| puts line }
    end

    IO.foreach("testfile") { |line| puts line }

写文件：?? (这一节哪里是在说写文件啊)

**10.4 谈谈网络**

Ruby 提供了套接字库来直接访问 tcp / udp / sock 等。在较高层次，提供了 lib/net 库来处理应用层协议。还可以通过 open-uri 库，直接使用 Kernel.open 方法打开一个 uri。

#### 第 11 章 - 线程和进程

这一章基本是把多线程的知识又温习了一遍。这是 ruby 对系统底层多线程的封装。

回头把 APUE 中这一部分内容再看一下。

创建线程：

    for page_to_fetch in pages
      threads << Thread.new(page_to_fetch) do |url|
        h = Net::HTTP::new(url, 80)
        puts "Fetching: #{url}"
        resp = h.get('/', nil)
        puts "Got #{url}: #{resp.message}"
      end
    end
    threads.each { |thr| thr.join }

使用 `Thread.new` 创建线程，后面跟一个 block 执行线程要做的事情。使用 `thread.join` 等待线程结束。

`Thread.current` 得到当前线程，`Thread.list` 得到一个所有线程的列表 ...

线程变量 (类似 windows 中的 TLS - Thread Local Storage)。线程 block 中定义的局部变量，其它线程不能共享。如果需要被访问，则需要借助线程变量。可以简单地把线程对象看作一个散列表，使用 `[]=` 写入元素，并使用 `[]` 读取。

    10.times do |i|
      threads[i] = Thread.new do
        sleep(rand(0.1))
        Thread.current["mycount"] = count
        count += 1
      end
    end
    threads.each { |t| t.join; print t["mycount"], "," }

线程和异常：如果 `abort_on_exception` 置为 false，那么未处理的异常只会杀死当前线程，否则杀死整个进程。

**11.2 控制线程调度器**

- `Thread.stop` 停止当前线程
- `thread.run` 安排运行特定线程
- `Thread.pass` 把当前线程调度出去，允许别的线程运行
- `thread.join` `thread.value` 挂起调用它们的线程，直接指定的线程结束为止

**11.3 互斥**

临界区，监视器，条件变量 ...

消费者与生产者模型，等待条件变量和对条件变量发信号。

    plays_pending = playlist.new_cond
    plays_pending.wait_while
    plays_pending.signal

**11.4 运行多个进程**

衍生新进程的几种方式：

1. system 命令：`system("tar xzf test.tgz")`
1. 反引号命令，其实和 system 命令是一样的
1. `IO.popen` 方法，可以和子进程通信

独立子进程：fork

关于多线程为什么比单线程跑得快(一般来说)，我又有了新的理解：

1. 如果是多核 CPU，多个线程将被分配到多个核上同时运行。
1. 对于单核 CPU，虽然是多线程，但同一时刻仍然只有一个线程在运行，其余线程处于空闲状态，那它跟单线程又有什么区别呢，我以前的理解是，它可以增大这个进程在整个系统所有进程中的 CPU 周期占比，比如说原来系统中有 10 个进程在跑，每个都是单线程，线程调度是平均的，那么这个进程的 CPU 周期占比是 10%，如果我把这个进程改成 5 个线程，那么它的占比就增加到了 36%。实际这根本不是主要原因，你想啊，实际在一个系统中，线程数成百上千，你增加的这几个线程跟总数一比，简直是九牛一毛。我现在的理解是，如果这些线程所做的事，仅仅是操作内存，那实际多线程跟单线程的效率是差不多的，但是如果一旦线程中涉及操作 IO，网络请求这种耗时操作，那么多线程的优势就很明显了。我们举个爬虫的例子，假设我们要爬 5 个网页，如果用单线程做，每爬一个网页，我们就要等一次网络请求的响应，总共要等 5 次，但如果我们用 5 个线程来做，当第一个线程进行到网络请求时，它阻塞等待，系统会马上切到第二个线程，当第二个线程阻塞时，系统继续切换线程，或许当第五个线程开始网络请求时，第一个线程和第二个线程的网络请求就已经回来了，这样我们等待网络请求的时间肯定是小于单线程下依次执行 5 次的时间的。当然，现在哪还有单核 CPU 啊，除非在嵌入式领域。

#### 第 12 章 - 单元测试

- 使用 Test::Unit 框架，使用时通过 `require 'test/unit'` 加载此框架。
- 测试用例 (test case) 必须继承自 Test::Unit::TestCase。
- 测试方法必须以 `test_` 开头。
- `setup` 和 `teardown` 方法将在每一个测试方法之前和之后执行。
- 使用 `assert_` 系列断言方法。

示例：

    require 'test/unit'
    require 'playlist_builder'
    require 'dbi'

    class TestPlaylistBuilder < Test::Unit::TestCase
      def setup
        @db = DBI.connect('DBI:mysql:playlist')
        @pb = PlaylistBuilder.new(@db)
      end

      def teardown
        @db.disconnect
      end

      def test_empty_playlist
        assert_equal([], @pb.playlist)
      end

      #...
    end

运行测试：

    $ ruby test_playlist_builder.rb

只执行其中某一个测试方法：

    $ ruby test_playlist_builder --name test_empty_playlist

#### 第 13 章 - 遇到问题时 (TroubleShooting)

ruby 提供了调试器，benchmark，profiler 的支持。
