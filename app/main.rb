# frozen_string_literal: true

def tick(args)
  args.state.sim_scale ||= 4
  args.state.setup_done ||= false
  args.state.cells_checked ||= 0
  args.state.debug ||= false

  if args.state.setup_done == false
    setup(args)
  else
    main_cycle(args)
  end

  args.state.debug = !args.state.debug if args.inputs.keyboard.key_up.tab

  args.outputs.sprites << { x: 0, y: 0, w: args.grid.w, h: args.grid.h, path: :field }
  if args.state.debug
    args.outputs.solids << { x: args.grid.left, y: args.grid.top - 50, w: 400, h: 50, a: 200 }
    args.outputs.labels << { x: args.grid.left, y: args.grid.top, text: "FPS: #{args.gtk.current_framerate}", r: 0,
                            g: 0, b: 255, size: 2 }
    perent = ((args.state.cells_checked / ((1280 / args.state.sim_scale) * (720 / args.state.sim_scale))) * 100).round(2)
    args.outputs.labels << { x: args.grid.left, y: args.grid.top - 20, text: "Cells Checked: #{args.state.cells_checked}/#{(1280 / args.state.sim_scale) * (720 / args.state.sim_scale)} - #{perent}%", r: 0,
                            g: 0, b: 255, size: 2 }
  end

  return unless args.state.setup_done == false

  args.outputs.labels << { x: args.grid.center_x, y: args.grid.center_y, alignment_enum: 1, text: 'Loading...', r: 0,
                           g: 255, b: 0 }
end

def setup(args)
  args.state.pixels ||= {}

  args.state.iter_y ||= 0
  iter_y = args.state.iter_y
  iter_x = 0

  if iter_y < args.grid.h
    while iter_x < args.grid.w
      args.state.pixels[iter_x] ||= {}
      args.state.pixels[iter_x][iter_y] = true if rand(2) == 1
      iter_x += args.state.sim_scale
    end
    iter_y += args.state.sim_scale
  end
  args.state.iter_y = iter_y

  args.state.setup_done = true if args.state.iter_y >= args.grid.h

  args.state.pixels.each_pair do |x_loc, value|
    args.render_target(:field).solids << value.map do |y_loc, _state|
      { x: x_loc, y: y_loc, w: args.state.sim_scale, h: args.state.sim_scale, path: :pixel }
    end
  end
end

def check_neighbor(args, _x_iter, _y_iter, n_x, n_y)
  if args.state.pixels.key?(n_x) && args.state.pixels[n_x].key?(n_y)
    true
  else
    false
  end
end

def main_cycle(args)
  # Cell Neighbors
  # 123
  # 4@6
  # 789

  next_tick = {}
  dead_cells_to_check = {}
  args.state.cells_checked = 0

  args.state.pixels.each_pair do |x_iter, value|
    args.state.cells_checked += value.length
    value.each_key do |y_iter|
      neighbors = 0

      n_locs = []
      n_locs[0] = { x: x_iter - args.state.sim_scale, y: y_iter - args.state.sim_scale }
      n_locs[1] = { x: x_iter, y: y_iter - args.state.sim_scale }
      n_locs[2] = { x: x_iter + args.state.sim_scale, y: y_iter - args.state.sim_scale }
      n_locs[3] = { x: x_iter - args.state.sim_scale, y: y_iter }
      n_locs[4] = { x: x_iter + args.state.sim_scale, y: y_iter }
      n_locs[5] = { x: x_iter - args.state.sim_scale, y: y_iter + args.state.sim_scale }
      n_locs[6] = { x: x_iter, y: y_iter + args.state.sim_scale }
      n_locs[7] = { x: x_iter + args.state.sim_scale, y: y_iter + args.state.sim_scale }

      n_locs.each do |location|
        if check_neighbor(args, x_iter, y_iter, location[:x], location[:y])
          neighbors += 1
        else
          break unless (location[:x]).positive? && location[:x] < args.grid.w
          break unless (location[:y]).positive? && location[:y] < args.grid.h

          dead_cells_to_check[location[:x]] ||= {}
          dead_cells_to_check[location[:x]][location[:y]] = false
        end
      end

      if [3, 2].include?(neighbors)
        next_tick[x_iter] ||= {}
        next_tick[x_iter][y_iter] = true
      end
    end
  end

  dead_cells_to_check.each_pair do |x_iter, value|
    args.state.cells_checked += value.length
    value.each_key do |y_iter|
      args.state.cells_checked += 1
      neighbors = 0

      n_locs = []
      n_locs[0] = { x: x_iter - args.state.sim_scale, y: y_iter - args.state.sim_scale }
      n_locs[1] = { x: x_iter, y: y_iter - args.state.sim_scale }
      n_locs[2] = { x: x_iter + args.state.sim_scale, y: y_iter - args.state.sim_scale }
      n_locs[3] = { x: x_iter - args.state.sim_scale, y: y_iter }
      n_locs[4] = { x: x_iter + args.state.sim_scale, y: y_iter }
      n_locs[5] = { x: x_iter - args.state.sim_scale, y: y_iter + args.state.sim_scale }
      n_locs[6] = { x: x_iter, y: y_iter + args.state.sim_scale }
      n_locs[7] = { x: x_iter + args.state.sim_scale, y: y_iter + args.state.sim_scale }

      n_locs.each do |location|
        neighbors += 1 if check_neighbor(args, x_iter, y_iter, location[:x], location[:y])
      end

      if neighbors == 3
        next_tick[x_iter] ||= {}
        next_tick[x_iter][y_iter] = true
      end
    end
  end

  args.state.pixels = next_tick

  args.state.pixels.each_pair do |x_loc, value|
    args.render_target(:field).solids << value.map do |y_loc, _state|
      { x: x_loc, y: y_loc, w: args.state.sim_scale, h: args.state.sim_scale, path: :pixel }
    end
  end
end
