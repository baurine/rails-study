# Sidekiq Note

## References

- [Sidekiq Wiki](https://github.com/mperham/sidekiq/wiki)
- [Sidekiq 教程](https://ruby-china.org/topics/19891)
- [Youtube Sidekiq](https://www.youtube.com/playlist?list=PLjeHh2LSCFrWGT5uVjUuFKAcrcj5kSai1)
- [Background Processing with Rails, Redis and Sidekiq](https://www.youtube.com/watch?v=GBEDvF1_8B8)

## Note

不是很复杂的东西，不用细看了，遇到问题时再查文档。

安装

    gem 'sidekiq'

编写 worker

    class HardWorker
      include Sidekiq::Worker
      def perform(name, count)
        # do something
      end
    end

生成 worker job 入队

    HardWorker.perform_async('bob', 5)

启动 sidekiq process 处理这些队列中的 job

    $ bundle exec sidekiq
