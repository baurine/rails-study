# Agile Web Development Rails 5 - Note 3

### 19. Active Record

#### Defining Your Data

在 `initializers/inflections.rb` 中可以修改一些默认的命名约定，比如单复数转换：

    ActiveSupport::Inflector.inflections do |inflect| 
      inflect.irregular 'tax', 'taxes'
    end

在 model 使用 `self.table_name` 来重新指定对应的表名：

    class Sheep < ApplicationRecord 
      self.table_name = "sheep"
    end

model 的其它一些方法：

    > Order.column_names
    > Order.columns_hash["pay_type"]

db 和 model 的数据类型有一个转换关系，比如 sql 中的 int 类型对应 ruby 的 Fixnum 类型，查看 db 中列的原始数据，即未转型前的数据：

    > Product.first.created_at_before_type_cast
    => "2017-04-29 07:32:13.849007"
    > Product.first.created_at
    => Sat, 29 Apr 2017 07:32:13 UTC +00:00

#### Locating and Traversing Records

model 通过 `self.primary_key`，要以替换默认的 id 列，指定其它列作为 `primary_key` 列，这样之后，在给 `model.id` 赋值时，实际是赋值给新的 `primary_key` 列。

    class LegacyBook < ApplicationRecord 
      self.primary_key = "isbn"
    end

    book = LegacyBook.new
    book.id = "0-12345-6789"
    book.title = "My Great American Novel"
    book.save
    # ...
    book = LegacyBook.find("0-12345-6789")
    puts book.title   # => "My Great American Novel" 
    p book.attributes # => {"isbn" =>"0-12345-6789",
                      #     "title"=>"My Great American Novel"}

`model.attributes` 等同于 `model.as_json`，输出 model 的 hash。

表的三种关联关系：一对一，一对多，多对多。

一对一：拥有外键的表，具有 `belongs_to` 声明，另一方则有 `has_one` 声明。

一对多：拥有外键的表，具有 `belongs_to` 声明，另一方则有 `has_many` 声明。

多对多：需要借助关联表，比如 product 有多个 category，而 category 也属于多个 product，那么关联表 `categories_products` 里的列为 `product_id`、`category_id`。product 和 category model 相互用 `has_and_belongs_to_many` 来声明对方。

    class Category < ActiveRecord::Base
      has_and_belongs_to_many :products
      # ...
    end

    class Product < ActiveRecord::Base
      has_and_belongs_to_many :categories
      # ... 
    end

哦，终于明白了原来 `has_and_belongs_to_many` 是用来干这个的，我以前的做法是通过 `has_many through` 来声明的，如下所示：

    class Category < ActiveRecord::Base
      has_many :categories_products # 这一行可有可无吧
      has_many :products, through: :categories_products
    end

通过后者这种方式来声明，关联表的表名是随便的，而前者的方式，由表名是固定的，由两个表按照字母排序通过下划线拼接在一起。然而我有一个疑问，像 `categories_products` 这样的表名，对应的 model 应该怎么命名，是 `CategoriesProduct` 还是 `CategoryProduct`，亦或是其它呢？

#### Creating, Reading, Updating and Deleting (CRUD)

**Creating**

使用 `new` 方法，然后 `save`，或者直接用 `create(hash)` 方法一步到位。

`new` 和 `create` 方法的参数支持 hash，`create` 方法还支持 hash 数组作为参数。

`new` 方法支持 block：

    Order.new do |o|
      o.name = "Dave Thomas" 
      #...
      o.save
    end

save， save!，create，create!

- save，成功返回 true，失败返回 nil
- save!，成功返回 true，失败抛出异常 RecordInvalid
- create，成功或失败都返回 model object，通过判断这个对象的 errors 来判断是否成功失败 (?? really)
- create!，成功返回 model object，失败抛出异常

**Reading**

无疑，这部分是重头戏。不过看下来后发现其实讲到的内容都已经用过了。

`find()`，参数是 `primary_key` 的值，而并不一定是 `id` 的值。如果记录不存在，这个方法会抛出 `ActiveRecord::RecordNotFound` 异常。

`find_by(hash)`，可以通过任意列及其值查找，如果记录不存在，返回 nil，不会抛出异常。

常见 sql 查询方法：where，order，limit，offset，select，joins，group ...

一些聚合统计方法：

    average = Order.average(:amount) # average amount of orders 
    max     = Order.maximum(:amount)
    min     = Order.minimum(:amount)
    total   = Order.sum(:amount)
    number  = Order.count

Scope：

      class Order < ApplicationRecord
        scope :last_n_days, ->(days) { where('updated < ?' , days) }
        scope :checks, -> { where(pay_type: :check) }
      end

      orders = Order.checks.last_n_days(7)

scope 之间可以链式调用。

`find_by_sql()`，通过原始的 sql 语句来查询。

find 系列方法，如果记录存在，则只返回结果中的第一条记录，即返回值是一个 model 对象，而不是 model 数组。

**Updating**

和 Creating 一条记录类似，Updating 也有两种方式，一种是在内存中修改后，调用 `save()` 保存，一种是直接用 `udpate(hash)` 一步到位，直接修改数据库。

`update_all(sql)`，修改所有符合条件的记录。

    result = Product.update_all("price = 1.1*price", "title like '%Java%'")

**Deleting**

1. `delete`，`delete_all`
1. `destroy`，`destroy_all`

第一种方法在数据库层面直接进行删除，第二种方法在 ActiveRecord 层面进行操作，会调用 model 的各种 callbacks。

使用示例：

    Order.delete(123)
    Order.first.delete
    User.delete([2,3,4,5])
    Product.delete_all(["price > ?", @expensive_price])

    order = Order.find_by(name: "Dave")
    order.destroy
    Order.destroy_all(["shipped_at < ?", 30.days.ago])

#### Participating in the Monitoring Process

Active Model 的生命周期的各种回调。

一图胜千言：

![](../art/agile-web-model-callbacks.png)

除了图中的回调外，还有比如 `after_find`，`after_initialize`。

`after_find` 在任何 `find` 操作后被调用。`after_initialize` 在 model create 后被调用。(那么和 `after_create` 的区别是什么？)

`before_validation` 和 `after_validation` 接受 `on: :create` 和 `on: :update` 参数。

定义 callback handler 的两种基本方式 -- 方法或 block：

    class Order < ApplicationRecord
      before_validation :normalize_credit_card_number 
      after_create do |order|
        logger.info "Order #{order.id} created"
      end

      protected
      def normalize_credit_card_number
        self.cc_number.gsub!(/[-\s]/, '')
      end
    end

可以为相同的 callback，比如 `before_create`，定义多个 handler，这些 handler 会按顺序依次执行，如果中间有某个 handler 返回了 false，那么调用就会被提前中断。

**Grouping Related Callbacks Together**

如果要定义一组相关的 callback，可以把它们定义在一个独立的 handler class 中，并且放在 `app/models` 目录下，这个 handler class 可以供多个 model 使用。在 handler class 中定义的方法名是固定的，和回调方法名一一对应，并且接受 model 作为参数，比如 `before_validation(model)`，`before_create(model)`。

示例：

    class CreditCardCallbacks
      # Normalize the credit card number
      def before_validation(model)
        model.cc_number.gsub!(/[-\s]/, '')
      end
    end

    class Order < ApplicationRecord
      credit_card_callbacks = CreditCardCallbacks.new
      before_validation credit_card_callbacks
      # ...
    end
    class Subscription < ApplicationRecord 
      credit_card_callbacks = CreditCardCallbacks.new
      before_validation credit_card_callbacks
      # ...
    end

上面的做法假设了 model 中都含 `cc_number` 这个属性，那如果有些 model 的这个作用的属性不叫 `cc_number` 这个名字呢，该怎么办，上面的做法耦合性太强了。我们可以换一种做法来降低这种依赖性，增强灵活性，我们在 Callback 的构造函数中把所需的属性名传进去，让这个属性名是可变的。

比如这样一个用来对 model 的多个属性进行加密和解密的 Callback Handler Class：

    class Encrypter
      # We're passed a list of attributes that should
      # be stored encrypted in the database
      def initialize(attrs_to_manage)
        @attrs_to_manage = attrs_to_manage
      end

      # Before saving or updating, encrypt the fields using the NSA and
      # DHS approved Shift Cipher
      def before_save(model)
        @attrs_to_manage.each do |field|
          model[field].tr!("a-z", "b-za")
        end
      end

      # After saving, decrypt them back
      def after_save(model)
        @attrs_to_manage.each do |field|
          model[field].tr!("b-za", "a-z")
        end
      end

      # Do the same after finding an existing record
      alias_method :after_find, :after_save
    end

使用：

    require "encrypter"
    class Order < ApplicationRecord
      encrypter = Encrypter.new([:name, :email])
      before_save encrypter
      after_save encrypter
      after_find encrypter

      protected
        def after_find
        end
    end

为什么要定义一个空的 `after_find` 方法，这是因为出于性能考虑，如果没有显式地定义一个 `after_find()` 方法，ActiveRecord 并不会去调用一个 `after_find` 回调，即使你指定了一个 `after_find` 回调。我想是因为 `find` 查询实在是太频繁了，所以 rails 不想让你轻易地使用 `after_find` 回调，因此增大了使用它的成本。

进一步优化，从上例可以看出，每一个想使用 Encrypter 的 model 都要重复上面七行代码，not cool！我们把这些逻辑放到基类的一个方法里，可以有多种方法，我们选择为 `ActiveRecord::Base` 扩展一个叫 `encrypt` 的方法：

    class ActiveRecord::Base
      def self.encrypt(*attr_names)
        encrypter = Encrypter.new(attr_names)
        
        before_save encrypter
        after_save  encrypter
        after_find  encrypter

        define_method(:after_find) { }
      end
    end

从上例中可以看出，ruby 有多么灵活，它可以在方法中动态地定义出一个方法来 (JavaScript 也可以)。

使用：

    class Order < ActiveRecord::Base
      encrypt(:name, :email)
    end

处理 model 的重复代码，还有一种选择是放到 concern 中，但这本书没有展开讲，只是提及了一下，参考阅读：[Put chubby models on a diet with concerns](https://signalvnoise.com/posts/3372-put-chubby-models-on-a-diet-with-concerns)。

**Transactions**

数据库的事物操作，将对数据库的一系列操作集合到一起，如果中途失败了，这些所有操作都将回滚，使之具有一种原子性。

一个例子：

    peter = Account.create(balance: 100, number: "12345")
    paul  = Account.create(balance: 200, number: "54321")

    Account.transaction do
      paul.deposit(350)
      peter.withdraw(350)
    end

由于 peter 没有足够的余额，导致 `peter.withdraw` 将失败 (`withdraw()` 方法内部失败将抛出异常)，从而导致 `paul.deposite()` 的操作也回滚。

但是要注意的是，虽然数据库的操作失败了，但 model 对象的值变化后并没有跟着回滚，因此此时，model 的值和数据库已不再同步。这是正常的，完全可以理解。

另外，当你使用 model 的 callback 时，比如 `dependent: :destroy`，`before_destroy: xxx`，rails 在内部就使用了 transaction，如果 callback 失败，将会引起一系列操作都回滚，比起你手动处理这些关联操作，这就是使用 callback 的好处，记住，优先使用 callback，但如果 callback 太影响性能，那就考虑手动处理，或直接操作数据库。(遇到的一个比较典型的例子就是，`destroy_all` 在操作大量数据时，因为同时会去删除和它有 `dependent: :destroy` 的记录，非常耗时，这时就要考虑用 `delete_all` 方法来替代，因为 `delete_all` 会跳过 ActiveRecord 层面，不关心任何回调，直接操作数据库。)

### 20. Action Dispatch and Action Controller

Action Pack 是 rails 的核心，它包括三部分：ActionDispatch，ActionController，ActionView。

- ActionDispatch：主要负责路由，接收请求，然后调用相应的 controller 的 action 方法。
- ActionController：处理请求，输出响应。
- ActionView：渲染响应。

不像 ActiveRecord 是独立存在的模块且可以用于非 web 的 Ruby 程序，以上三部分是紧密关联的，无法单独使用。

#### Dispatching Requests to Controllers

介绍了一些路由的写法，但并没有覆盖很全面，可以说只涉及了 routes 的极少部分。

resources：

    resources :products

默认 resources 产生 7 种 action (index，new，create，show，edit，update，destroy)，可以限制只产生部分或排除部分 action：

    resources :comments, except: [:update, :destroy]
    resources :comments, only: [:new, :create]

在 resources 上添加额外的 action：

    resources :proudcts do
      get :who_bought, on: :member
    end

`on: :member` 表示 `who_bought` 只作用在单个 product 上，如果要作用在 products 集合上，使用 `on: :collection`。

嵌套的 resources：

    resources :products do
      resources :reviews
    end

Routing Concerns，如果 product 和 user 都有 review，为了避免写相同的代码，可以使用 concern：

    concern :reviewable do
      resources :reviews
    end

    resources :products, concern: :reviewable
    resources :users, concern: :reviewable

Shallow Route Nesting：

    resources :products, shallow: true do 
      resources :reviews
    end

    /products/1         => product_path(1)
    /products/1/reviews => product_reviews_index_path(1)
    /reviews/2          => reviews_path(2)

响应不同数据格式的请求，`respond_to`：

    def show
      respond_to do |format|
        format.html
        format.json { render json: @product.to_json }
      end
    end

请求非 html 的 2 种形式：

    GET /products/123.json
    GET /products/123?format=json

#### Processing of Requests

请求的处理流程：当请求到达时，ActionDispatch 通过路由表找到对应的 controller action 方法，如果这个 action 方法未定义，则找 controller 中的 `method_missing()` 方法，如果没有方法被调用，ActionPack 就去找和 action 同名的 view 模板，如果找到了，就渲染此模板并返回给客户端，否则抛出 `AbstractController::ActionNotFound` 异常。

**Controller Environment**

在 action 方法被调用之前，controller 负责为 action 创建各种环境，主要是访问 request 的各种方法：

- `action_name`
- cookies
- headers：注意，不要在 headers 里操作 cookie，操作 cookie 用上面的 cookies 方法
- params
- request：表示请求对象
  - `request_method`：:delete，:get，:head，:post，:put 等
  - method：基本和 `request_method` 一样，但不包括 :head，:head 在这里将返回 :get
  - delete?，get?，head?，post?
  - `xml_http_request?`，`xhr?`：两者等于，用于判断是否是 ajax 请求
  - url：返回 URL 完整值
  - protocol，host，port，path，query_string
  - domain
  - `host_with_port`
  - `post_string`
  - ssl?
  - `remote_ip`
  - env：`request.env['HTTP_ACCEPT_LANGUAGE']`，获取浏览器定义的一些环境变量值
  - accepts：header 中 Accept 属性中指定的 Mime::Type 数组
  - format：根据 Accept header 计算出来的值，类似 Mime::HTML，Mime::JSON ??
  - `content_type`
  - headers：怎么又有一个 headers，是不是和上面的 headers 是相同值 ??
  - body
  - `content_length`

实际上这些功能都是由一个叫 Rack 的 gem 来实现的。

- response
- session

Action Pack 还有一个贯穿整体的功能模块，前面也讲到过了，就是 logger。

**Responding to the User**

响应的三种方式：

1. 渲染 `render()`
1. 跳转 `redirect_to()`
1. 返回文件 `send_xxx()`

如果在 action 中上面三种方法都没有调用，controller 会自动 render 和 action 同名的 view template。

**Rendering Templates**

说明 `render()` 的 n 种用法，这里列举了多达 11 种用法，感觉大部分都不常用。这里面有一种需要特别注意，`render(action: action_name)`，比如 `render(action: :edit)`，这个方法调用后，并不会去执行 `edit` action，只会去渲染 `edit` action 对应的 view 模板。

另外，从常识来说，一般以为，在 action 方法中调用了 `render()` 方法后，整个流程应该就中止了，后面的语句应该不再执行了，但在 rails 中并不是这样的，如果 `render()` 后面还有语句，而且 `render()` 后并没有 `return`，那么后面的语句就还会继续执行，如果后面还有 `render()` 方法，那么就会在一次 action 中执行多次 render，controller 会抛出异常。如下例所示：

    # DO NOT DO THIS
    def update
      @user = User.find(params[:id])
      if @user.update(user_params)
        render action: :show
      end
      render template: "fix_user_errors"
    end

`render()` 方法还接受三个选项：`:status`，`:layout`，`:content_type`。

`:layout` 用来设置渲染 view 模板时是否包括 `/layouts/application.html.erb` 的内容。(我自己这么理解的)

`:content_type` 用来设置 response header 的 `Content-Type` 值。

`render_to_string()` 方法，用法和 `render()` 差不多，但它的结果不会放到 response 中，不会返回给浏览器，可以在开发阶段用来调试，方便查看渲染结果。而且它在一次 action 中多次调用并不会引发异常。

**Sending Files and Other Data**

1. `send_data(data, options...)`
1. `send_file(path, options...)`

**Redirects**

1. `redirect_to(action, options)`
1. `redirect_to(path)`
1. `redirect_to(:back)`：跳转回 header 中 `HTTP_REFERER` 值指定的 url。

#### Objects and Operations That Span Requests

- session
- flash
- callback

**Rails Sessions**

session 用来保持状态，不要和 cookie 混淆，它们只是有一点点交集而已。

**Session Storage**

session 的存储方式 `session_store`，在 rails 中多达 6 种：

- `:cookie_store`
- `:active_record_store`
- `:drb_store`
- `:mem_cache_store`
- `:memory_store`
- `:file_store`

这 6 种方式，除了第一种 `:cookie_store` 是存储在客户端的 cookie 中，其余都是在服务端进行状态的持久化。cookie 只是实现 session 的手段之一，而且在 rails 中这是默认的实现方式。

我认为，人们常说的 cookie 有广义和狭义之分，广义的 cookie，就是被浏览器客户端持久化的这些对象，会在每次请求时被浏览器自动携带，它包括狭义的 cookie 和 session。狭义的 cookie 就是所有的 cookie 中除去 session 数据的那部分。

如果采用 `:cookie_store` 方式的 session，数据失效很好处理，关闭浏览器，再打开浏览器，cookie 中的 session 部分就会被自动清空，所以这种方式 session 的有效周期维持在一个浏览器进程时长。这种方式将减轻服务端逻辑。但 `:cookie_store` 方式只适合存储比较小量的数据，比如只存一个 `user_id`。

如果采用服务端方式的 session，session 的生命周期是永久的，因此必须借助过期时间来清除过期的 session。另外，要注意，采用服务端方式的 session，并不是说就不需要往客户端的 cookie 中存储任何数据了，还是需要的，只不过只需要存储一个 `session_id`，然后通过 `session_id` 到服务端再去拿对应的其它数据。

正因为 session 在客户端的实现总是要借助 cookie，这就是为什么我们很容易把它和 cookie 混淆。

session 在 cookie 中存储的数据，一般都是以加密形式存在的，至少在 rails 中是这样的，在服务端用密钥 (一般是对称密钥) 加密，返回给客户端，客户端请求时带上 session，然后在服务端再进行解密。

而 cookie 中除了 session 的数据外，其它的一般来说是明文的。

其它参考：

- [[译] Rails Sessions 是如何工作的？](http://grantcss.com/blog/2015/03/23/how-rails-sessions-work/)

**Flash - Communicating Between Actions**

flash 用来在相邻两个 action 之前传递数据，因为只有 `redirect_to()` 可以实现 action 的跳转，因此 flash 主要就是和 `redirect_to()` 配套使用。

flash 是基于 session 来实现的，但它的生命周期比一般的 session 又短了很多，可以说是极短的，只能维持一个 action 的时长，在一个 action 中赋值，在下一个 action 中作用并失效。 (?? 内部到底是怎么实现的呢)

如果想让 flash 在当前 action 生效，那么使用 `flash.now()`，`flash.now()` 将更新 flash 的值但不会把它加到 session 里。

**Callbacks**

action 的 callback，有三类：

- before callback：`before_action`
- after callback：`after_ation`
- around callback：`around_action`

它们都接受 `:only` 和 `:except` 参数，callback 默认作用在所有 action 上，使用这两个参数可以使其仅作用或不作用在某些 action 上。

其它辅助方法：`skip_before_action` 和 `skip_after_acion`，在继承中，子类用这些方法来跳过在父类中定义的一些 callback。

`before_action` 和 `after_action` 都很好理解，分别作用在 action 之前和之后。因为它们定义的回调都可以是多个，因此，这个 callback 将按照队列依次调用。

在 `before_action` 回调中，如果有一个 callback 返回 false，或者调用了 `render()` 或 `redirect_to()`，整个流程就会被中断。

`after_action` 一般用来修改 response，或者压缩 response。

`around_action` 就很有趣了，很类似 koa 的机制，一种 middleware 的思想。是 `before_action` 和 `after_action` 的综合。它先执行一部分代码，当它遇到 `yield` 时，就会去执行相应的 aciton，当执行完 action 后，再去执行 `yield` 后面的代码。所以 `yield` 之前的代码相当于 `before_action`，`yield` 之后的代码相当于 `after_action`。如果这个 `around_action` 没有执行 `yield`，那么相应的 action 就不会执行，这相当于 `before_action` 返回了 false。
