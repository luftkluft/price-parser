require './ruby-progressbar_/output'
require './ruby-progressbar_/outputs/tty'
require './ruby-progressbar_/outputs/non_tty'
require './ruby-progressbar_/timer'
require './ruby-progressbar_/progress'
require './ruby-progressbar_/throttle'
require './ruby-progressbar_/calculators/length'
require './ruby-progressbar_/calculators/running_average'
require './ruby-progressbar_/components'
require './ruby-progressbar_/format'
require './ruby-progressbar_/base'

class ProgressBar
  def self.create(*args)
    ProgressBar::Base.new(*args)
  end
end
