class Player

  DIRECTIONS = [:forward, :left, :right, :backward]

  def each_direction(&block)
    DIRECTIONS.each do |direction|
      yield(direction)
    end
    nil
  end

  def initialize()
    @health = 20
  end

  def play_turn(warrior)
    @warrior = warrior
    @enemys_count = DIRECTIONS.count { |dir| @warrior.feel(dir).enemy? }
    @captives_count = DIRECTIONS.count { |dir| @warrior.feel(dir).captive? }
    @listen = @warrior.listen

    bind_enemy || shoot || handle_low_health ||rescue_captive || walk

    @health = warrior.health
  end

  def walk
    dir = direction_to_walk
    @warrior.walk!(direction_to_walk)
    return true
  end

  def empty_tower?
    @listen.count{ |space| space.enemy? || space.captive?} == 0
  end

  def empty_space
    DIRECTIONS.find { |dir| @warrior.feel(dir).empty? && !@warrior.feel(dir).stairs? }
  end

  def direction_to_walk
    if empty_tower?
      dir = @warrior.direction_of_stairs
    else
      enemy_space = @listen.find{ |space| space.enemy? }
      captive_space = @listen.find{ |space| space.captive? }
      if enemy_space
        dir = @warrior.direction_of(enemy_space)
      elsif captive_space
        dir = @warrior.direction_of(captive_space)
      end

      if dir && @warrior.feel(dir).stairs?
        dir = empty_space
      end
    end

    dir
  end

  def under_attack?
    @health > @warrior.health
  end

  # Rest on low_health when no under attack
  def handle_low_health
    if @warrior.health < 20
      @warrior.rest!
      return true
    end
  end

  # Try to resuce captives
  def rescue_captive
    each_direction do |dir|
      #Rescue near captive
      if @warrior.feel(dir).captive? && @warrior.feel(dir).unit.character == "C"
        @warrior.rescue!(dir)
        return true
      end

      #Rescue enemy if no more enemies
      if @enemys_count.zero? && @warrior.feel(dir).captive? && @warrior.feel(dir).unit.character != "C"
        @warrior.rescue!(dir)
        return true
      end
    end
  end

  def bind_enemy
    if @enemys_count > 1
      dir_with_enemy = DIRECTIONS.find { |dir| @warrior.feel(dir).enemy? }
      if dir_with_enemy
        @warrior.bind!(dir_with_enemy)
        return true
      end
    end
  end

  # Shoot enemys nearby
  def shoot
    each_direction do |dir|
      if @warrior.feel(dir).enemy?
        @warrior.attack!(dir)
        return true
      end
    end
  end
end
