# Agile Web Development Rails 5 - Note 4

### 21. Action View

#### Using Template

在模板中可以访问到环境：

- controller 对象中所有的实例变量
- controller 对象中的 flash、headers、logger、params、request、response 和 session，但除了 flash，其它不推荐直接在模板中访问，其余方法在模板中直接访问的一个场景是用于在调试模式下输出当前值：

        <h4>Session</h4> <%= debug(session) %>
        <h4>Params</h4> <%= debug(params) %>
        <h4>Response</h4> <%= debug(response) %>

- 在模板中使用 `controller` 可以直接访问到当前 controller，`controller.controller_name` 可以得到当前 controller 的类名
- `base_path` 得到当得模板所在路径

模板的种类：

- `.builder`：产生 xml 格式的 response
- `.coffee`：javascript 模板
- `.erb`：一般用于产生 html 格式的 response，完整的格式是 `html.erb`
- `.scss`：css

其实还有挺多的啊，比如 `.jbuilder`，而且这些后缀都可以组合使用的，然后这些后缀从后往前，会依次调用相应的解析器。

#### Generating Forms

form 的各种输助方法：

- `form_for(model)`
- `text_field`，`text_area`，`search_field`，`telephone_field`，`url_field`，`email_field`，`number_field`，`range_field`，`email_field`
- `select`，`date_select`，`time_select`
- `hidden_field`，`password_field`
- `file_field`

#### Uploading Files to Rails Applications

通过 form 和 `file_field` 上传图片文件。在服务端直接把图片二进制存储在数据库表中，用 data 列存储二进制数据，name 列存储文件名，`content_type` 存储文件类型。

这其中用到的一些知识点：

**验证文件格式**

    validates_format_of :content_type,
                        with: /^image/,
                        message: "must be a picture"

**定义虚拟列**

在 view 模板中，定义了文件列为 `uploaded_picture`，`<%= form.file_field("uploaded_picture") %>`，但实际数据库中并不存在这一列，因此它是虚拟的，我们可以在 `picture.rb` 手动定义这样一个方法：

    def uploaded_picture=(picture_field)
      self.name = base_part_of(picture_field.original_filename)
      self.content_type = picture_field.content_type.chomp
      self.data = picture_field.read
    end

这样，存储的时候就很简单了：

    @picture = Picture.new(picture_params)
    @picture.save

**在 view 中显示上传的图片**

    <h3><%= @picture.comment %></h3>
    <img src="<%= url_for(:action => 'picture', :id => @picture.id) %>"/>

    def picture
      @picture = Picture.find(params[:id])
      send_data(@picture.data,
                filename: @picture.name,
                type: @picture.content_type,
                disposition: "inline")
    end

#### Using Helpers

自己定义 helper 方法，使用内置的丰富的 helper 方法。

如果要在 view 模板中使用一些复杂的逻辑，尽量把这些逻辑抽取到 helper 方法中。

**用于格式化的内置 helper 方法**

    <%= distance_of_time_in_words(Time.now, Time.local(2016, 12, 25)) %>
    4 months
    <%= distance_of_time_in_words(Time.now, Time.now + 33, include_seconds: false) %>
    1 minute
    <%= distance_of_time_in_words(Time.now, Time.now + 33, include_seconds: true) %>
    Half a minute
    <%= time_ago_in_words(Time.local(2012, 12, 25)) %>
    7 months
    <%= number_to_currency(123.45) %>
    $123.45
    <%= number_to_currency(234.56, unit: "CAN$", precision: 0) %>
    CAN$235
    <%= number_to_human_size(123_456) %>
    120.6 KB
    <%= number_to_percentage(66.66666) %>
    66.667%
    <%= number_to_percentage(66.66666, precision: 1) %>
    66.7%
    <%= number_to_phone(2125551212) %>
    212-555-1212
    <%= number_to_phone(2125551212, area_code: true, delimiter: " ") %>
    (212) 555 1212
    <%= number_with_delimiter(12345678) %>
    12,345,678
    <%= number_with_delimiter(12345678, delimiter: "_") %>
    12_345_678
    <%= number_with_precision(50.0/3, precision: 2) %>
    16.67

`debug()` 方法用于 dump 当前变量的值，输出格式为 yaml：

    <%= debug(params) %>

    --- !ruby/hash:HashWithIndifferentAccess name: Dave
    language: Ruby
    action: objects
    controller: test

截断高亮文本：

    <%= simple_format(@trees) %>
    Formats a string, honoring line and paragraph breaks. You could give it the plain text of the Joyce Kilmer poem Trees, and it would add the HTML to format it as follows.
    <p> I think that I shall never see <br />A poem lovely as a tree.</p> <p>A tree whose hungry mouth is prest <br />Against the sweet earth’s flowing breast; </p>

    <%= excerpt(@trees, "lovely", 8) %>
    ...A poem lovely as a tre...

    <%= highlight(@trees, "tree") %>
    I think that I shall never see A poem lovely as a <strong class="high- light">tree</strong>. A <strong class="highlight">tree</strong> whose hungry mouth is prest Against the sweet earth’s flowing breast;

    <%= truncate(@trees, length: 20) %>
    I think that I sh...

处理单复数：

    <%= pluralize(1, "person") %> but <%= pluralize(2, "person") %>
    1 person but 2 people

**生成链接的 helper 方法**

- `link_to`，`button_to`，`link_to_unless_current`，`image_tag`，`mail_to`，
- `stylesheet_link_tag`，`javascript_include_tag`
- `auto_discovery_link_tag` (产生 rss 链接)

配置 asset 的根路径 (默认为当前域名)：

    config.action_controller.asset_host = "http://media.my.url/assets"

(哎！一想到这么多丰富的 helper 方法，如果使用前后端分离的构造，这些方法都不能在 javascript 中使用，真是可惜，不知道有没有这些方法的 javascript 库? 难道是 loadsh??)

#### Reducing Maintenance with Layouts and Partials

layout 和 partial 用来渲染共页面需要复用的布局。

(这一部分的表述有点混乱...自己明白就行)

**Layout**

    <% yield :layout %>

controller 的 action 中 render 出来的内容，被 rails 存储在 :layout 中，上面的语句 `yield :layout` 就是用来获得 :layout 的值。:layout 是 render 方法渲染后内容的默认符号，所以 `yield` 等同于 `yield :layout`。

这一小节想要表达的，其实是，在 layout 中可以通过 `yield` 来得到 action 中 render 的内容，并不是说 action render 的内容是 layout。

所以 action 的 render 方法执行在前，layout 的 render 执行在后。

**Locationg Layout Files**

`app/views/layouts/` 目录下的 `application.html.erb` 会应用到所有 controller，我们可以在这个目录下定义其它 layout，并在 controller 中通过 layout 方法指定新的全局 layout。layout 方法同时接受 except 和 only 参数。

    class StoreController < ApplicationController
      layout "standard", except: [ :rss, :atom ]
      # ...
    end

如果 layout 方法指定的值为 nil，表示不使用一个全局 layout。

允许在运行时改变全局 layout：

    class StoreController < ApplicationController
      layout :determine_layout 
      # ...

      private
      def determine_layout
        if Store.is_closed?
          "store_down"
        else
          "standard"
        end
      end
    end

(所以，`layout :determine_layout` 相当于定义了一个回调，就像 `before_action` 一样)

另外，单个 action 在进行 render 时，也可以同时指定单独的 layout：

    def rss
      render(layout: false) # never use a layout
    end

    def checkout
      render(layout: "layouts/simple")
    end

**Passing Data to Layouts**

layout 和普通的模板一样，可以访问到所有 controller 中的实例变量，它还可以访问到在普通模板中定义的实例变量，因为如上面所说，普通模板的渲染在前，layout 模板渲染在后。

普通模板，定义了 @title：

    <% @title = "My Wonderful Life" %>
    <p>
      Dear Diary:
    </p>
    <p>
      Yesterday I had pizza for dinner. It was nice.
    </p>

在 layout 中可以使用这个 @title：

    <html>
      <head>
        <title><%= @title %></title>
        <%= stylesheet_link_tag 'scaffold' %>
      </head>

      <body>
        <h1><%= @title %></h1>
        <%= yield :layout %>
      </body>
    </html>

可以在普通模板中通过 `content_for(:content_name)` 定义一部分 view，这部分 view 不会直接渲染在普通模板中，要真正渲染它，可以在 layout 中通过 `yield :content_name` 来渲染。

普通模板：

    <h1>Regular Template</h1>

    <% content_for(:sidebar) do %>
      <ul>
        <li>this text will be rendered</li>
        <li>and saved for later</li>
        <li>it may contain <%= "dynamic" %> stuff</li>
      </ul>
    <% end %>

    <p>
      Here's the regular stuff that will appear on
      the page rendered by this template.
    </p>

layout：

    ...
    <%= yield :sidebar %>

**Partial-Page Templates**

partial templates 一般用来显示列表中的单个元素布局 (但也不限于，像是 `_form.html.erb`)。必须以下划线开头，另外，它默认包含一个和模板名同名 (但不包括下划线) 的局部对象，比如 `_article.html.erb` 中默认有一个叫 `article` 的对象。

`app/views/articles/_article.html.erb`：

    <div class="article">
      <div class="articleheader">
        <h3><%= article.title %></h3>
      </div>

      <div class="articlebody">
        <%= article.body %>
      </div>
    </div>

在其它模板中使用 `render(partial:)` 方法来渲染 partial 模板。

    <%= render(partial: "article", object: @an_article) %>

在 `render()` 方法中通过 locals 参数给 partial 模板传递更多局部变量：

    render(partial: 'article',
           object: @an_article,
           locals: { authorized_by: session[:user_name],
                     from_ip:       request.remote_ip })

**Partials and Collections**

在 `render()` 方法中使用 collection 参数，指定一个集合，它会将集合中的每一个元素传进 partial 模板，然后依次渲染每一个元素。同时，还可以使用 `spacer_template` 参数指定每个 partial 模板之间的隔离模板。

    <%= render(partial:         "animal", 
               collection:      %w{ ant bee cat dog elk },
               spacer_template: "spacer")
    %>

**Shared Templates**

shared 模板本质上还是 partial 模板，也需要用下划线开头。但它一般不用来渲染一个列表，而是用来渲染类似 header，footer 之类的共用布局。默认存放目录 `app/views/shared`。

    <%= render("shared/header", locals: {title: @article.title}) %>
    <%= render(partial: "shared/post", object: @article) %>

**Partials with Layouts**

还可以定义 partial layout，也是下划线开头，存放在相应 controller 目录下，和 partial 模板是一样的存放目录。

partial 模板可以和一个 parial layout 渲染。

    <%= render partial: "user", layout: "administrator" %>

    <%= render layout: "administrator" do %> # ...
      #...
    <% end %>

这里的 administrator partial 布局存放在 `app/views/users/_administrator.html.erb`。

**Partials and Controllers**

略。

### 22. Migrations

#### Creating and Running Migrations

    $ bin/rails db:migrate
    $ bin/rails db:migrate:status
    $ bin/rails db:migrate      VERSION=xxxx
    $ bin/rails db:migrate:up   VERSION=xxxx
    $ bin/rails db:migrate:down VERSION=xxxx
    $ bin/rails db:migrate:redo STEP=3
    $ bin/rails db:rollback

#### Anatomy of a Migration

    class SomeMeaningfulName < ActiveRecord::Migration
      def up
        add_column :orders, :e_mail, :string
      end
      def down
        remove_column :orders, :e_mail
      end
    end

但是 rails 足够智能，像 `add_column` 这种 migration，rails 知道对应的 rollback 是 `remove_column`，在这种情况况，我们可以用一个 `change()` 方法来替代 `up()` 和 `down()`。

    class AddEmailToOrders < ActiveRecord::Migration
      def change
        add_column :orders, :e_mail, :string
      end
    end

但是对于 rails 不知道该如何 rollback 的 migration，还是就手动定义 `down()` 和 `up()`。

**Column Types**

列的类型，rails 中的 model 列的类型，对应不同的数据库，相应的数据库的数据类型是不一样的，比如 rails 中 `:binary` 类型，对应到 mysql 是 `blob`，psql 是 `bytea`。但是我们不用关心，这些数据库适配器帮我们做好了转换。

rails 中列的类型有以下几种：`:binary`、`:boolean`、`:date`、`:datetime`、`:decimal`、`:float`、`:integer`、`:string`、`:text`、`:time`、`:timestamp` (同 `:datetime`)

`add_column` 方法对一些类型支持以下 option：

- `null: true/false`
- `limit: size`
- `default: value`
- `precision: number`
- `scale: number`

`precision` 和 `scale` 只对 `:decimal` 有效。(对 float 不管用吗??)

    add_column :orders, :attn, :string, limit: 100
    add_column :orders, :order_type, :integer
    add_column :orders, :ship_class, :string, null: false, default: 'priority'
    add_column :orders, :amount, :decimal, precision: 8, scale: 2

**Renaming Columns**

    def change
      rename_column :orders, :e_mail, :customer_email
    end

`rename_column` 是 reversible 的，所以只需要定义 `change()` 方法就行了。

**Changing Columns**

使用 `change_column`，但它不是 reversible 的，所以需要同时定义 `up()` 和 `down()`，如果 `up()` 以后不想让它 `down()`，因为这样会造成已有的数据丢失，可以在 `down()` 方法是抛出 `IrreversibleMigration` 异常。

    class ChangeOrderTypeToString < ActiveRecord::Migration
      def up
        change_column :orders, :order_type, :string, null: false
      end
      def down
        raise ActiveRecord::IrreversibleMigration
      end
    end

#### Managing Tables

上面讲的是操作表中的列，这小节讲的操作表。

使用 `create_table` 方法新建一个表，因为它是 reversible 的，所以在 `change()` 方法中使用。

    def change
      create_table :order_histories do |t|
        t.integer :order_id, null: false
        t.text :notes
        t.timestamps
      end
    end

`t.timestamp` 将生成 `created_at` 和 `updated_at` 列。

**Renaming Tables**

使用 `rename_table` 方法。

**定义索引**

`add_index`：

    def change
      add_index :orders, :name
    end

**Primary Keys**

在 `create_table` 方法中通过 `primary_key` 参数指定新的列作为 `primary_key`，替代默认的 id 列，通过 `id: false` 参数创建没有 `primary_key` 列的表。

    create_table :tickets, primary_key: :number do |t|
      t.text :description
      t.timestamps
    end

    create_table :authors_books, id: false do |t|
      t.integer :author_id, null: false
      t.integer :book_id, null: false
    end

剩作的使用极少，略暂。

### 23. Nonbrowser Applications

如何在一个非 web 项目中，比如我只想操作数据库，使用 rails 的部分功能，比如 ActiveRecord。

原始一些的方法：

    require "active_record"

    ActiveRecord::Base.establish_connection(adapter: "sqlite3",
    database: "db/development.sqlite3")

    class Order < ApplicationRecord
    end

    order = Order.find(1)
    order.name = "Dave Thomas"
    order.save

简单一些的方法：

    require "config/environment.rb"

    order = Order.find(1)
    order.name = "Dave Thomas"
    order.save

其它略，需要用到时再细看。(第一眼看到这章标题时，我还以为要讲的 rails for API 呢...)

### 24. Rails' Dependencies

#### Generating XML with Builder

略。view 后缀 `.xml.builder`。

(我倒是关心 Generating JSON with JBuilder，但是可惜这本书完全没讲到。)

#### Generating HTML with ERB

view 后缀 `.html.erb`。

默认 `<%= %>` 中产生的文本将原样显示，即比如产生了 `<h1>hello</h1>` 这样的内容，并不会把 `<h1>` 翻译成 html 元素，如果想把文本中的 html 元素按 html 显示，那么使用 `raw()` 方法，但存在风险，使用 `sanitize()` 方法可以剔除文本中的有风险的部分，比如 `<form>` 和 `<javascript>` 标签。

#### Managing Dependencies with Bundler

略。

#### Interfacing with the Web Server with Rack

略。

#### Automating Tasks with Rake

把一些额外的独立的 task 放到 `lib/tasks` 目录下，用 rake 来执行 (rails 5.0 以后也可以用 rails 来执行)

    # lib/tasks/db_backup.rake
    namespace :db do
      desc "Backup the production database"
      task :backup => :environment do
        # ...
      end
    end

一些输助命令：

    $ rake --trace --dry-run db:setup
    $ rake --tasks //列举所有 tasks

### 24. Rails Plugins

#### Beautifying Our Markup with Haml

    %p#notice= notice

    %h1= t('.title_html')

    - cache @products do
      - @products.each do |product|
        - cache product do
          .entry
            = image_tag(product.image_url)
            %h3= product.title
            = sanitize(product.description)
            .price_line
              %span.price= number_to_currency(product.price)
              = button_to t('.add_html'),
                line_items_path(product_id: product, locale: I18n.locale),
                remote: true

- `- ` 开头的表示 ruby 语句，但是不产生输出
- `= ` 后面的代码也是 ruby 语句，但是会产生输出。它可以独立一行，也可以跟在 html 元素后，此时，`=` 要紧贴着 html 元素，不能有空格
- `%` 表示一个 html 元素，比如 `%p`，表示 `<p></p>`，默认的 `%div` 可以省略
- `.` 表示 class，`#` 表示 id
- `,` 表示行的连续

haml 的缩进对齐很重要，像 python 一样是有语法意义的。

#### Pagination

    def index
      @orders = Order.order('created_at desc').page(params[:page])
    end

    <p><%= paginate @orders %></p>

在 view 中使用 `paginate` 辅助方法，将产生分页链接。

从这一章还学习到，除了可以把单独的 task 放到 `lib/tasks` 目录下，通过 `bin/rails` 直接运行，还可以放到 `script/` 目录下，然后通过 `rails runner` 命令来运行，比如：

    # script/fake_orders.rb
    Order.transaction do
      (1..100).each do |i|
        Order.create(name: "Customer #{i}", address: "#{i} Main Street", email: "customer-#{i}@example.com", pay_type: "Check")
      end
    end

    $ rails runner script/fake_orders.rb

----

全书 DONE!

希望本书能讲但没有能的内容：用 jbuilder 产生 json，rails for API，用 resque 执行定时任务。只能自己再看了。

本书和 *Ruby on Rails Tutorial* 一书的比较，后者的例子丰富一些，复杂一些，而且是真正的 TDD，html 布局使用了比较多的 html5 标签，比如 `<nav>`、`<section>`，但是，在讲完例子后，并没有像本书一样，在例子之后，再重新把这些知识点深入一些地，串联地讲解，因此本书的知识面更比后者广。总之，两本书都值得看几遍。
