class Player

  DIRECTIONS ||= [:forward, :left, :right, :backward]
  OPOSITE_DIRS ||= {
    forward: :backward,
    left: :right,
    right: :left,
    backward: :forward
  }

  def initialize()
    @health = 20
    @last_walk_dir = :forward
  end

  def play_turn(warrior)
    @warrior = warrior
    @listen = @warrior.listen

    bind_enemy || handle_low_health || rescue_ticking ||
      detonate_bomb || shoot || rescue_captive || walk

    @health = warrior.health
  end

  def bind_enemy
    if feel_enemies_count > 1
      dir_with_enemy = enemy_to_bind_dir
      if dir_with_enemy
        @warrior.bind!(dir_with_enemy)
        return true
      end
    end
  end

  # Rest on low_health when no under attack
  def handle_low_health
    ticking_space = @listen.find { |space| space.ticking? }
    if !(ticking_space && no_enemies?)
      if ticking_space
        if @warrior.health < 13 && !under_attack?
          @warrior.rest!
          return true
        end
      else 
        if !(ticking_space && no_enemies?) && @warrior.health < 16 && !under_attack?
          @warrior.rest!
          return true
        end
      end
    end
  end

  # Try to resuce ticking captives
  def rescue_ticking
    each_direction do |dir|
      if @warrior.feel(dir).captive? && real_captive?(dir)
        @warrior.rescue!(dir)
        return true
      end
    end

    ticking_space = @listen.find { |space| space.ticking? }
    if ticking_space
      dir = @warrior.direction_of(ticking_space)
      if @warrior.feel(dir).enemy?
        distance = @warrior.distance_of(ticking_space)
        new_dir = empty_dir
        if new_dir && new_dir != OPOSITE_DIRS[@last_walk_dir]
          dir = new_dir
        else
          return true if detonate_bomb_to(dir)
          return true if shoot_to(dir)
        end
      end
      walk_to(dir)
      return true
    end
  end

  def detonate_bomb
    each_direction do |dir|
      return true if detonate_bomb_to(dir)
    end
  end

  def detonate_bomb_to(dir)
    return false if @warrior.health <= 4
    look = @warrior.look(dir)
    amount = look.count { |space| space.enemy? }
    if amount > 1 && @warrior.feel(dir).enemy?
      @warrior.detonate!
      return true
    end
  end

  # Shoot enemys nearby
  def shoot
    each_direction do |dir|
      return true if shoot_to(dir)
    end
  end

  def shoot_to(dir)
    if @warrior.feel(dir).enemy?
      @warrior.attack!(dir)
      return true
    end
  end

  # Try to resuce captives
  def rescue_captive
    each_direction do |dir|
      #Rescue near captive
      if real_captive?(dir)
        @warrior.rescue!(dir)
        return true
      end

      return true if rescue_enemy_captive(dir)
    end
  end

  def rescue_enemy_captive(dir)
    #Rescue captive enemy if no more enemies
    if feel_enemies_count.zero? && enemy_captive?(dir)
      @warrior.rescue!(dir)
      return true
    end
  end

  def walk
    walk_to(direction_to_walk)
  end

  def walk_to(dir)
    @warrior.walk!(dir)
    @last_walk_dir = dir
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
        dir = empty_dir
      end
    end

    dir
  end

  def enemy_to_bind_dir
    ticking_space = @listen.find { |space| space.ticking? }
    ticking_dir = @warrior.direction_of(ticking_space) if ticking_space

    (DIRECTIONS - [ticking_dir]).find { |dir| @warrior.feel(dir).enemy? }
  end

  def feel_enemies_count
    DIRECTIONS.count { |dir| @warrior.feel(dir).enemy? }
  end

  def empty_tower?
    @listen.count{ |space| space.enemy? || space.captive?} == 0
  end

  def no_enemies?
    @listen.count{ |space| space.enemy?} == 0
  end

  def under_attack?
    feel_enemies_count > 0 && @health > @warrior.health
  end

  def empty_dir
    DIRECTIONS.find { |dir| @warrior.feel(dir).empty? && !@warrior.feel(dir).stairs? }
  end

  def each_direction(&block)
    DIRECTIONS.each do |direction|
      yield(direction)
    end
    nil
  end

  def enemy_captive?(dir)
    @warrior.feel(dir).captive? && @warrior.feel(dir).unit.character != "C"
  end

  def real_captive?(dir)
    @warrior.feel(dir).captive? && @warrior.feel(dir).unit.character == "C"
  end
end
