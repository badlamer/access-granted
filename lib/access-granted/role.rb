module AccessGranted
  class Role
    attr_reader :name, :user, :conditions, :permissions, :scopes

    def initialize(name, conditions = nil, user = nil, block = nil)
      @user         = user
      @name         = name
      @conditions   = conditions
      @block        = block
      @permissions = []
      @scopes = []

      if @block
        instance_eval(&@block)
      else
        configure
      end
    end

    def configure
    end

    def scope(action, subject, conditions = {}, &block)
      add_scope(action, subject, conditions, block)
    end

    def can(action, subject = nil, conditions = {}, &block)
      add_permission(true, action, subject, conditions, block)
    end

    def cannot(action, subject, conditions = {}, &block)
      add_permission(false, action, subject, conditions, block)
    end

    def find_scope(action, subject)
      scopes.detect do |scope|
        scope.action == action && scope.matches_subject?(subject)
      end
    end

    def find_permission(action, subject)
      permissions.detect do |permission|
        permission.action == action &&
          permission.matches_subject?(subject) && \
          permission.matches_conditions?(subject)
      end
    end

    def applies_to?(user)
      case @conditions
      when Hash
        matches_hash?(user, @conditions)
      when Proc
        @conditions.call(user)
      else
        true
      end
    end

    def matches_hash?(user, conditions = {})
      conditions.all? do |name, value|
        user.send(name) == value
      end
    end

    def add_scope(action, subject, conditions, block)
      prepare_actions(action).each do |a|
        raise DuplicateScope if find_scope(a, subject)
        scopes << Scope.new(a, subject, @user, conditions, block)
      end
    end

    def add_permission(granted, action, subject, conditions, block)
      prepare_actions(action).each do |a|
        raise DuplicatePermission if find_permission(a, subject)
        permissions << Permission.new(granted, a, subject, @user, conditions, block)
      end
    end

    private

    def permission_exists?(_action, subject)
      permissions.any? do |permission|
        permission.matches_subject?(subject)
      end
    end

    def prepare_actions(action)
      if action == :manage
        [:read, :create, :update, :destroy]
      else
        Array(*[action])
      end
    end
  end
end
