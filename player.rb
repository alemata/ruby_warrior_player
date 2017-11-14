class Player

  DIRECTIONS = [:forward, :backward]

  def each_direction(&block)
    DIRECTIONS.each do |direction|
      yield(direction)
    end
    nil
  end

  def initialize()
    @health = 20
    @direction = :forward
  end

  def play_turn(warrior)
    @warrior = warrior
    rescue_captive || attack || handle_low_health || walk

    @health = warrior.health
  end

  def under_attack?
    @health > @warrior.health
  end

  def walk
    if @warrior.feel.wall?
      @warrior.pivot!
      return true
    else
      @warrior.walk!
      return true
    end
  end

  def handle_low_health
    if @warrior.health < 10
      if under_attack? && !@warrior.feel(:forward).enemy?
        @warrior.walk!(:backward)
        return true
      end
    end

    if @warrior.health < 20
      if !under_attack?
        @warrior.rest!
      else
        @warrior.walk!
      end
      return true
    end
  end

  def rescue_captive
    each_direction do |dir|
      #Rescue near captive
      if @warrior.feel(dir).captive?
        @warrior.rescue!(dir)
        return true
      end

      #See if there are any captive to rescue nearby
      spaces = @warrior.look(dir)
      space = spaces.find{ |space| space.captive? }
      if space
        @warrior.walk!(dir)
        return true
      end
    end
  end

  def attack
    dir = dir_with_archer
    if dir
      @warrior.shoot!(dir)
      return true
    else
      each_direction do |dir|
        enemy_to_shoot = enemy_to_shoot?(dir)
        if enemy_to_shoot
          @warrior.shoot!(dir)
          return true
        end
      end
    end
  end

  def dir_with_archer
    DIRECTIONS.find do |dir|
      # Check if there is an archer to shoot in the dir direction
      enemy_to_shoot?(dir, "a")
    end
  end

  def enemy_to_shoot?(dir, character = nil)
    spaces = @warrior.look(dir)
    space = spaces.find{ |space| space.enemy? }
    if space
      not_captives = spaces[0..space.location.first - 1].all? { |space| !space.captive? }
      return not_captives && space.unit.character == character if character
      return not_captives
    end
  end
end
