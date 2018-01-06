# Rails Misc Note

会记录一些 rails 项目中遇到的比较常见的问题及解决方法。

1. gem & bundle
1. rvm & gemset
1. sort by associate count
1. 多态 (Polymorphic)
1. ActiveRecord 的一些补充
1. migration 的教训
1. index 的重要性

## gem & bundle

查看一个项目中 gem 安装在何处：

    $ gem which [gem_name]
    $ bundle show [gem_name]

例如：

    $ gem which capistrno
    ---/.rvm/gems/ruby-2.3.0/gems/capistrano-3.9.0/lib/capistrano.rb
    $ bundle show capistrano
    ---/.rvm/gems/ruby-2.3.0/gems/capistrano-3.9.0

通过 gem help 查看 gem 的命令：

    $ gem help
    $ gem help commands

其它一些有用的命令：

    # 查看已安装的 gem
    $ gem list

    # 查看 ruby 的环境变量
    $ gem env

    # 这个命令有意思，启动一个 http 服务器查看已安装的所有 gem 的信息
    $ gem server

## rvm & gemset

rvm 用来管理 ruby 版本，gemset 是 rvm 的功能之一，用来管理 gem 包版本。rvm 官网 [rvm.io](https://rvm.io/)

rvm 其实跟 rails 没有什么关系，但 rvm 是 rails 开发中常用的工具之一。

新 clone 一个 rails 工程，需要指定 ruby 版本，且安装的 gem 不要影响现有的其它 rails 工程，该怎么做呢。

首先，进入当前工程目录，用 `rvm list` 列举当前系统安装的 ruby 版本：

    > rvm list

    rvm rubies

       ruby-1.9.3-p484 [ x86_64 ]
       ruby-2.2.0 [ x86_64 ]
    =* ruby-2.3.0 [ x86_64 ]
       ruby-2.3.2 [ x86_64 ]
       ruby-2.3.3 [ x86_64 ]

    # => - current
    # =* - current && default
    #  * - default

如果没有所需要的 ruby 版本，则用 `rvm install` 安装，安装之前可以用 `rvm list known` 查看一下当前都有哪些版本，然后从中选一个。

    > rvm install 2.4.1

如果已经安装了所需版本，但不是当前使用的版本，则用 `rvm use` 切换版本：

    > rvm use 2.4.1

用 `rvm current` 查看当前使用的 ruby 版本，当然用上面的 `rvm list` 也是可以的。

我们可以把目标版本号写到当前目录下的 `.ruby-version` 配置文件中，这样，每次进入这个目录时，就会自动切换到这个 ruby 版本，不需要我们再手动运行 `rvm use` 来切换。

    > echo '2.4.1' > .ruby-version

然后，我们创建一个 gemset 来存放此工程用到的所有 gem，一般 gemset 的名称为项目名称，或加上环境，比如 `myweb`，`myweb_staging`，`myweb_production`：

    > rvm gemset create myweb

然后，用 rvm gemset use 命令来切换到使用此 gemset：

    > rvm gemset use myweb

之后，运行 `bundle` 后所安装的 gem 就会放在此 gemset 所对应的目录中。

我们可以把 gemset 写到 `.ruby-gemset` 中，这样，每次进入这个目录时，就会自动切换到这个 gemset，不用再手动运行 `rvm gemset use` 命令。

    > echo 'myweb' > .ruby-gemset

需要注意的是，gemset 是与 ruby 版本号相关的，如果在 ruby 2.4.1 下创建，那么就只有在 ruby 2.4.1 下生效，如果切换了另一个 ruby 版本，这个 gemset 就不存在。所以，实际这个 gemset 的全名是 `2.4.1@myweb`，可以用 `rvm use` 命令一步到位，同时指定使用的 ruby 版本和 gemset：

    > rvm use 2.4.1@myweb

可以把 `.ruby-version` 和 `.ruby-gemset` 的内容写到一个配置文件 `.versions.conf` 中，格式如下：

    ruby=ruby-2.4.1
    ruby-gemset=myweb

当你使用了一个新的 gemset 后，你会发现，执行 `rails s` 或 `bin/rails s` 出错，提示 rails 不存在之类的错误，于是你继续 `bundle`，仍然提示 bundle 不存在。你感到一阵困惑后马上醒悟过来，因为使用了 gemset 后，所有的 gem 都从相应的 gemset 中取，而 rails 和 bundle 也是 gem，此时的 gemset 是空的，什么都没有，自然提示找不到 rails 和 bundle。

所以，新建 gemset 后，要重装先安装 bundler，再用 bundler 的 bundle 命令去安装其它 gem。

    > gem install bunlder
    > bundle

## sort by associate count

根据关联记录的数量来排序。比如有一个用户表 users 和评论表 reviews，有些用户可能有多个评论，有些用户没有评论。现在有一个显示所有用户及它的评论数的页面，要求可以按照评论数来对用户进行排序。

此时，如果用默认的 joins 即 inner join，会发现，那些评论数为 0 的用户不见了。怎么办呢，用 `left_joins`，如下所示：

    User.left_joins(:reviews)
        .group(:id)
        .order('count(reviews.id) desc')

注意，order 中的必须是 `count(reviews.id)` 或 `count(reviews.*)`，而不能是 `count(*)`，因为对于评论数为 0 的用户来说，`count(*)` 的结果是 1，而 `count(reviews.*)` 的结果才是正确的 0。

我也写了一部分解释在 [Postgresql Study Note](https://github.com/baurine/study-note/blob/master/database/postgresql-study-note.md) 中。

## 多态 (Polymorphic)

一般的文章讲多态只讲到 model 怎么写，忽略了 route 和 controller 该怎么写，找到了一篇讲解多态并包含 route 和 controller 的文章，可以认为是最佳实践：[Polymorphic Routes in Rails](http://thelazylog.com/polymorphic-routes-in-rails/)。(但这篇文章没有讲到 migration 该怎么写，我应该再写一篇文章，把二者结合起来)。

使用：<http://caok1231.com/rails/2014/10/13/many-to-many-and-polymorphic.html>

剩下的待补充。

## ActiveRecord 的一些补充

1. enum 的使用：[关于在 Rails Model 中使用 Enum (枚举) 的若干总结](https://ruby-china.org/topics/28654)

   ActiveRecord 是对 DB Table 的一层封装，属性和表中的列的类型并不完全相同。enum 声明的属性，在 ActiveRecord 中的类型是 String，在 table 中是 Integer，ActiveRecord 会自动完成类型的转换。

   一些补充：[Rails 中 Database table / ActiveRecord / ObjectType 关系](https://github.com/baurine/graphql-study/blob/master/notes/appendix.md)

1. jsonb 类型的列

   jsonb 类型的引入让 PostgreSQL 有了类似 MongoDB 的能力，可以在此类型的列中存入任意类型的值，别看它名字中有 json，实际并不是只能存 json 格式的内容。我试过了，存 Integer，String，Hash 等都是可以的。但是要记住，你用什么类型存进去的，取出来就要按这种类型处理。

## migration 的教训

结论：不要在 migration 中进行耗时过长的操作，应该让 migration 的时间尽可能短，把耗时的操作放到 rake task 中，之后自己 ssh 到服务器操作或用 capistrano 辅助。

起因：有一个 podcasts 的表，每个 podcast 有多个 episodes，现在要给 podcasts 表增加一列 `average_duration`，这个值是 podcast 的所有 episodes 的 duration 的平均值。

这个增加列的 migration 是很简单的：

    add_column :podcasts, :average_duration, :float

考虑到执行这个 migration 后，我们还要为这一列计算值，以往我是把这种事情放在 rake task 中做的，比如：

    task cal_podcast_average_duration: :environment do
      Podcast.order(id: :desc).each(&:cal_duration)
    end

这样，布署之后，我们还需要手动 ssh 到服务器上执行这个 task。

但这次，我想节省掉手动执行 task 这个步骤，想把这个事情放到 migration 中进行，这样，布署的时候就可以把这件事一块做了。

代码大致是这样的：

    def change
      add_column :podcasts, :average_duration, :float

      reversible do |change|
        change.up do
          Podcast.order(id: :desc).each(&:cal_duration)
        end
      end
    end

但是，由于疏忽，episodes 表中的 `podcast_id` 索引没做，而且由于数量巨大，这次的 migration 耗时漫长。这样导致的后果：

1. 布署过程中一旦网络中断，布署将失败。而如果放到 rake task 中做，虽然也很耗时，但我们可以在服务器上使用 tmux 来做这件事，不用担心网络中断问题。
1. 另外，如果放到 rake task，我们可以在布署后，给 episodes 表的 `podcast_id` 加上索引后，再执行这个 rake task，很灵活，但在 migration 中就不能这样做。

虽然问题是由索引引起的，但从这次事件中明白，migration 应该越快越好，布署也要越快越好，耗时操作放到 rake task 中进行。

## index 的重要性

意识到 index 的重要性是从上面的事件中感受到的。在没有为 episodes 表的 `podcast_id` 列加索引前，migration 耗时达一个多小时，每个 podcast 耗时数百毫秒，加索引后，仅耗时数毫秒，差距几百倍，最终耗时从一个多小时降到了几分钟。

平时怎么来注意这个索引的问题呢：

1. 看 production.log，看哪个 sql query 耗时
1. 用 `pg_top` 工具