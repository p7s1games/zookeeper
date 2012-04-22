require 'zookeeper'
require 'eventmachine'

module ZookeeperEM 
  class Client < Zookeeper
    # @private
    # the EM Connection instance we receive once we call EM.watch on our selectable_io
    attr_reader :em_connection

    def initialize(*a, &b)
      @on_close       = EM::DefaultDeferrable.new
      @on_attached    = EM::DefaultDeferrable.new
      @em_connection  = nil
      logger.debug { "ZookeeperEM::Client obj_id %x: init" % [object_id] }
      super(*a, &b)
      on_attached.succeed
    end

    # EM::DefaultDeferrable that will be called back when our em_connection has been detached
    # and we've completed the close operation
    def on_close(&block)
      @on_close.callback(&block) if block
      @on_close
    end

    # called after we've successfully registered our selectable_io to be
    # managed by the EM reactor
    def on_attached(&block)
      @on_attached.callback(&block) if block
      @on_attached
    end

    def dispatch_next_callback(hash)
      EM.schedule { super(hash) }
    end

    # this is synchronous, but since the API still allows attaching to on_close, 
    # we just fake it here
    def close(&block)
      on_close(&block).tap do |d|
        super()
        d.succeed
      end
    end

    # Because eventmachine is single-threaded, and events are dispatched on the
    # reactor thread we just delegate this to EM.reactor_thread?
    def event_dispatch_thread?
      EM.reactor_thread?
    end
  end # Client
end # ZookeeperEM

