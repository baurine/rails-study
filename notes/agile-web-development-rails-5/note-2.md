# Agile Web Development Rails 5 - Note 2

### 12. Task G：Check Out!

#### Capturing an Order

创建订单，将 cart 中的 line items 转移到 order 中，并将 cart 销毁。

涉及到的新的知识点，定义 order 的 `pay_type` 时，在数据库层面的类型是 integer，但在 model 层面，使用了 enum 类型来约束它的范围，并在 form 中使用 select 来显示 `pay_type` 的值。

`order.rb`：

    class Order < ApplicationRecord
      enum pay_type: {
        "Check"          => 0,
        "Credit card"    => 1,
        "Purchase order" => 2,
      }
      validates :name, :address, :email, presence: true
      validates :pay_type, inclusion: pay_types.keys
      ...

`orders/_form.html.erb`：

    <div class="field">
      <%= f.label :pay_type %>
      <%= f.select :pay_type, Order.pay_types.keys,
                  prompt: 'Select a payment method' %>
    </div>

`button_to` 也可以生成 get 请求的 form，它会生成 `url?params` 的请求：

    <%= button_to "Checkout", new_order_path, method: :get %>

#### Atom Feeds

为 product 生成 `who_bought` 的 atom feed。

rails 居然原生支持 rss feed，有点惊讶。

`who_bought` 只作用在某个 product 上，所以路由的定义是这样的：

    resources :product do
      get :who_bought, on: :member
    end

`on: :member` 就表示 `who_bought` 只作用在某个 product 上，比如 `products/3/who_bought`，而不会作用在 product 集合上，比如 `products/who_bought`。

### 13. Task H：Sending Mail

#### Sending Confirmation Emails

当订单创建和出货时，给用户发送邮件，使用 rails 的 Action Mailer。

分三步走：

**1. Action Mailer 的配置**

配置 action mailer 的发送方式，有三种：`:smtp`，`:sendmail`，`:test`，第一种是默认，第二种是本机上的第三方邮件服务，比如 sendgrid，第三种用于测试，并不真正发送邮件。

    config.action_mailer.delivery_method = :smtp

如果 test/development/staging/production 使用一样的配置，那么可以将配置写到 config/environment.rb 中，否则，写到 config/environments 目录下对应环境的文件中，比如 config/environments/development.rb 中。

如果选择了 `:smtp` 或 `:sendmail` 方式，则还需要配置 `smtp_settings`，比如：

    config.action_mailer.smtp_settings = {
      address:              "smtp.gmail.com",
      port:                 587,
      domain:               "domain.of.sender.net",
      authentication:       "plain",
      user_name:            "dave",
      password:             "secret",
      enable_starttls_auto: true
    }

**2. 创建 Action Mailer Controller 和 View**

使用 `g scaffold mailer` 来生成和 mailer 相关的 controller 和 view：

    $ rails g scaffold mailer Order received shipped

实现 OrderMailer：

    class OrderMailer < ApplicationMailer
      default from: 'Sam Ruby <depot@example.com>'

      def received(order)
        @order = order
        mail to: order.email, subject: 'Pragmatic Store Order Confirmation'
      end

      def shipped(order)
        @order = order
        mail to: order.email, subject: 'Pragmatic Store Order Shipped'
      end
    end

这里面最关键的就是 mail 方法，参数有 `:to`，`:from`，`:subject`，`:cc`，`:bcc` 等。

每一个 action 方法都会去渲染和方法名字相同的 view，比如 received 方法会去找到 `received.html.erb` 或 `received.text.erb` 模板进行渲染，如果两者都存在，那么两个都渲染，这个是正常的 controller 的行为不太一样，所以我们一般只保留一种格式的模板，html 或 text，而把另一种删除。

同时修改 `mailers/preview/order_mailer_preview.rb`，以方便预览邮件内容。

修改相应的 view 模板。

**3. 发送邮件**

在订单生成的时候，调用 `OrderMailer.receiver(@order).deliver_later` 真正地向用户发送邮件。

    # orders_controller.rb
    if @order.save
      Cart.destroy(session[:cart_id])
      session[:cart_id] = nil
      OrderMailer.received(@order).deliver_later

(但这里我比较好奇的是，received 方法在定义的时候，并没有定义成类方法，而是实例方法，但这里调用的时候为什么是按类方法调用的呢? 这里有一个解释：<http://smsohan.com/blog/2011/01/28/actionmailer-3-why-do-you-call-instance/>)

#### Integration Testing of Applications

集成测试，测试一个用户购买一本书的整个流程。

rails 的集成测试，是测试每一个 use case。

貌似 rails 里的单元测试和 java 里的单元测试的概念不尽然相同啊，java 里的单元测试，指的是对一个类的一个方法进行测试，而在 rails 里，指的是对一个 model 的属性进行各种判断。而 rails 的 controller/mailer 的功能测试，对应到 java 里，其实也算是单元测试。

rails 的测试分类：

1. model 的单元测试，`test/models`
1. controller 的功能测试，`test/controllers`
1. mailer 的功能测试，`test/mailers`
1. 集成测试，`test/integration`

在此例中，因为邮件发延迟发送的，是放在一个待发送队列中，因此 rails 提供了 `perform_enqueued_jobs` 的 helper 方法来辅助。

### 14. Task I：Loggin In

用户登录系统，用户权限控制。

(总体感觉这一章的内容，在这本书上讲得会让你觉得很简单，不复杂，而在 ruby on rails tutorial 这本书上，把这部分内容复杂化了。)

(另外，ruby on rails tutorial 一书总体还是遵循了 TDD，先写驱动，再实现功能，而此书是先实现功能，再写测试。)

#### Adding Users

创建 User scaffold，包括 UsersController，User model 及相关的 view，实现 user 的注册。

在创建 scaffold 时，使用 `password:digest` 指定 password 为 digest 类型，这样，生成的 model，将会有 `password` 和 `password_confirmation` 两个虚拟属性 (在数据库中并不真实存在)，以及 `password_digest` 的真实属性 (在数据库中有真实的列)，两个虚拟属性是通过 model 中的 `has_secure_password` 方法实现的。

    class User < ApplicationRecord
      validates :name, presence: :true, uniqueness: :true
      has_secure_password
    end

#### Authenticate Users

创建 SessionsController 用于实现用户的登录，而且并没有对应的 session model，而是使用 user model。

登录后，将 user id 存在 `session[:user_id]` 中，登出时，将 `session[:usre_id]` 置为 nil。

在生成用户登录的 form 时，由于此时我们并没有一个相应的 session model，所以我们不能用 `form_for(model_obj)` 方法了，而是用 `form_tag` 来手动实现整个 form，相应的 `f.text_filed` 都要用对应的 `text_field_tag` 来替换。

    <%= form_tag do %>
      <fieldset>
        <legend>Please Login</legend>

        <div>
          <%= label_tag :name, 'Name:' %>
          <%= text_field_tag :name, params[:name] %>
        </div>

        <div>
          <%= label_tag :password, 'Password:' %>
          <%= password_field_tag :password, params[:password] %>
        </div>

        <div>
          <%= submit_tag 'Login'%>
        </div>
      </fieldset>
    <% end %>

路由的定义：

    controller :sessions do
      get     'login'  => :new
      post    'login'  => :create
      delete  'logout' => :destroy
    end

#### Limiting Access

使用 `before_action` 实现在每一个 action 之前检查用户是否登录，实现在基类 ApplicationController 中：

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      before_action :authorize

      protected
        def authorize
          unless User.find_by(id: session[:user_id])
            redirect_to login_url, notice: 'Please login'
          end
        end
    end

然后在子类中，用 `skip_before_action :authorize` 为不需要检查权限的 action 跳过这个回调。

增加 `before_action :authorize` 的回调后，对我们的测试产生了很大的影响，我们用 `setup` 方法来实现在每个测试之前先进行用户登录：

    # test/test_helper.rb
    class ActionDispatch::IntegrationTest
      def login_as(user)
        post login_url, params: { name: user.name, password: 'secret' }
      end

      def logout
        delete logout_url
      end

      def setup
        login_as users(:one)
      end
    end

#### Adding a Sidebar，More Administration

在 User model 中使用 `after_destroy` callback 来禁止删除最后一个用户，当用户数为 0 时，在回调中抛出异常，然后在 UsersController 中使用 `rescue_from` 来捕捉并处理这个异常。

    class User < ApplicationRecord
      ...
      after_destroy :ensure_an_admin_remains

      class Error < StandardError
      end

      private
        def ensure_an_admin_remains
          if User.count.zero?
            raise Error.new "Can't delete last user"
          end
        end
    end

### 15. Task J：I18n

实现部分页面的国际化，即多语言支持，包括货币，model 的错误信息的翻译，语言的动态切换。

#### Selecting the Locale

i18n 的初始化放在 `config/initializers/i18n.rb` 中。

翻译文件都放在 `config/locales` 目录下，一般约定以 locale 命名文件，比如 `en.yml`，`es.yml`。`I18n.available_locales` 得到的就是 `config/locales` 目录下所有文件支持的语言。

实际上 `config/locales` 目录下的文件名是可以随便取的，文件里的内容决定了我们得到的 `I18n.availabel_locales` 的值，比如，我在 locales 目录下只放置一个叫 `anythings.yml` 的文件，里面的内容如下：

    en:
      hello: 'hello'

    es:
      hello: 'hi'

那么 `I18n.available_locales` 得到的值是 `[:en, :es]`。

修改路由，使 locale 成为 url 中的一部分，加上括号表示其可选：

    scope '(:locale)' do
      resources :orders
      resources :line_items
      resources :carts
      root 'store#index', as: 'store_index', via: :all
    end

`via: :all` 表示支持所有的 http 方法，比如 GET/POST/DELETE。(感觉 rails route 简直是最复杂的一部分，规则太多了)

经常在 `rails routes` 的输出中看到 `(.:format)`，这表示请求格式参数是可选的，我们可以在请求的 url 后面加上 `.html`，`.json`，`.xml` 这种格式参数，也可以不加。

在基类 ApplicationController 中为所有 action 加上回调 `before_action :set_i18n_locale_from_params`。

#### Translating the Storefront / Tranlating Checkout

为界面上需要翻译的地方进行翻译。

一些技术点：

1. `t('.home')`，以 `.` 为前缀的 key，表示省略了默认的前缀，默认的前缀为此文件所处的目录级别，比如此文件处理 `views/layouts/application.html.erb`，那么省略的前缀为 `layouts.application`。

1. `t('.title_html')`，以 `_html` 结尾的 key，表示会对其值自动做 `html_safe` 转换，这样的值里面一般包含了 html 转义字符。

1. 对货币单位的国际化，在相应语言下定义 `number.currency.format`，如下所示：

        es:

          number:
            currency:
              format:
                unit:      "$US"
                precision: 2
                separator: ","
                delimiter: "."
                format:    "%n&nbsp;%u"

1. 对 active model 的 validation 出错消息进行国际化，在相应语言下定义 `activerecord.errors.messages`。

1. 对 active model 的属性显示名称进行国际化，在相应语言下定义 `activerecord.models` 和 `activerecord.attributes.model`：

        activerecord:
          models:
            order:       "pedido"
          attributes:
            order:
              address:   "Direcci&oacute;n"
              name:      "Nombre"
              email:     "E-mail"
              pay_type:  "Forma de pago"

1. `raw` 方法在多语言字符串中使用插值：

        errors:
            header:
              other:     "%{count} errores han impedido que este %{model} se guarde"

        <h2><%= raw t('errors.template.header',
                      count: order.errors.count,
                      model: t('activerecord.models.order')) %></h2>

#### Add a Locale Switcher

实现了一个 Locale Switch，使用 `<select>` 控件。

这里使用了一个小技巧，来兼容两种情况：允许 JavaScript 和不允许 JavaScript 的情况。当不允许 JavaScript 的时候，会显示一个 submit 的按钮来提交表单，当允许 JavaScript 时，用 JavsScript 代码隐藏 submit 按钮，并且当 `<select>` 的值改变时，自动提交表单。虽然这种兼容性的处理在现代 web 开发中已经不需要了 (哪个网页能离得开 JavaScript 啊)，但这种思想还是很妙的，而且学习到了如何自动提交表单。

    <%= form_tag store_index_path, class: 'locale' do %>
      <%= select_tag 'set_locale',
          options_for_select(LANGUAGES, I18n.locale.to_s),
          onchange: 'this.form.submit()' %>
      <%= submit_tag 'submit' %>
      <%= javascript_tag "$('.locale input').hide()" %>
    <% end %>

`I18n.locale.to_s`，为什么 `I18n.locale` 要 `to_s` 呢，因为 `I18n.locale` 的值是符号，而不是字符串。将符号转换成字符串用 `to_s`，将字符串转换成符号呢，用 `to_sym`，比如：

    > "es".to_sym
    => :es

最后，发现一个奇怪的问题，当访问首页时，如果我切换过一次语言，比如把默认的 en 改成 es，之后再访问首页，不停地刷新，发现几次中就能刷出一次默认语言为 es 来，非常奇怪。我的猜测：rails 使用了线程池，当我在某一次把 `I18n.locale` 改成 es 后，这个线程的 `I18n.locale` 就固定为 es 了，当我之后不停地刷新后，总有一次能用回这个线程，然而由于访问首页时，并没有指定语言，因此根据实现的逻辑，是不会去修改这个 `I18n.locale` 值的，因此它的值还是原来的 es。

验证猜想的方法：

1. 重启服务器，访问首页，不要切换语言，不停刷新首页，预期结果是不会出现 es 的页面，结果也是如此。
1. 只要切换过一次语言，之后再刷新，总有机率能刷出 es 的页面。

解决办法，修改 `set_i18n_locale_from_params` 方法的逻辑。

原来的逻辑：

    def set_i18n_locale_from_params
      if params[:locale]
        if I18n.available_locales.map(&:to_s).include?(params[:locale])
          I18n.locale = params[:locale]
        else
          flash.now[:notice] = "#{params[:locale]} translation not available"
          logger.error flash.now[:notice]
        end
      end
    end

修改后的逻辑：

    def set_i18n_locale_from_params
      if params[:locale]
        if I18n.available_locales.map(&:to_s).include?(params[:locale])
          I18n.locale = params[:locale]
        else
          I18n.locale = I18n.default_locale
          flash.now[:notice] = "#{params[:locale]} translation not available"
          logger.error flash.now[:notice]
        end
      else
        I18n.locale = I18n.default_locale
      end
    end

测试后发现问题已经不存在了。

### 16. Task K：Deployment and Production

这一章讲的是如何将 rails app 布署到 production 服务器。

没有很仔细地看，简单地了解了整个过程，需要使用 Apache, MySQL，Passenger，Capistrano。不过我们的项目一般用的是 Ngnix 和 PostgreSQL。

capistrano 会在工程目录下生成 `Capfile`，`config/deploy.rb`，`config/deploy/[environment].rb` 等文件。

布署 production 的命令：`cap production deploy`，回滚：`cap production deploy:rollback`。

### 17. Depot Retrospective

复盘整个 depot 项目，都做了哪些工作。

- Model
- View
- Controller
- Configuration
- Testing
- Deployment

`rails stats` 命令查看代码统计。
 
## Part 3 - Rails in Depth

### 18. Finding Your Way Around Rails

工程目录下的各个文件和目录的作用。

lib 目录下存放独立于 controller/view/model 逻辑的代码，比如类似生成 pdf 的逻辑，解析 rss 的逻辑。当 rails 启动时 lib 目录里的文件已经不会再处动加载了，需要把 lib 目录加到 rails 的自动加载目录配置中。

    # config/application.rb
    config.autoload_paths += %W(#{Rails.root}/lib)

如果不将 lib 目录配置到自动加载目录中，你也可以在需要这些文件的地方手动 require 所需文件，比如用 `require "shipping/airmail"` 来加载 `lib/shipping/airmail.rb` 文件。

(controllers/concern 用来存放 controller 共用的逻辑，models/concern 用来存放 models 共用的逻辑，app/helpers 目录用来存放 view 的辅助方法)。

lib/tasks 目录下存放用 rake 来执行的 `.rake` 文件，不属于 `rails server` 启动后的服务的一部分，可以单独在命令行执行，一般用于执行 migration 任何，文件以 `.rake` 结尾。

    # lib/tasks/db_schema_migrations.rake
    namespace :db do
      desc "Prints the migrated versions"
      task :schema_migrations => :environment do
        puts ActiveRecord::Base.connection.select_values(
        'select version from schema_migrations order by version' )
      end
    end

可以用 rails 或 rake 命令来执行这个 task：

    $ [RAILS_ENV=test/staging/production] bin/rails db:schema_migrations
    $ [RAILS_ENV=test/staging/production] bin/rake db:schema_migrations

bin 目录存放可执行的脚本或命令，一般是 wrapper。

bin/rails 脚本可执行的操作：

    $ bin/rails console/dbconsle/destroy/generate/new/runner/server

config 目录存放各种配置，包括路由 (routes.rb)，数据库 (database.yml)，initializer (`initializers/*.rb`)，locale (`locales/*.yml`)，deployment (`deploy/*.rb`，deploy.rb) 等。

在 server 启动之前，会最先加载 `config/environment.rb` 和 `config/application.rb`，其次是 `config/environments` 目录下各环境对应的配置。

启动 server 时指定环境，除了可以用 `RAILS_ENV` 来指定，还可以用 `-e` 来指定：

    $ rails server -e production

**Naming Conventions**

其它略。

controller 需要分组时，在 controllers 目录下建立子目录，比如 `controllers/admin` 目录，在 admin 目录中的 controller 都将置于 `Admin` module 下。同时，相应的 view 也将置于 `views/admin` 目录下。
