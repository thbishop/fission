module Fission
  class Command
    class Clone < Command
      def self.execute(args)
        unless args.count == 2
          Fission.ui.output help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for clone command", 1
        end

        source_vm = args.first
        target_vm = args[1]

        unless Fission::VM.exists? source_vm
          Fission.ui.output_and_exit "Unable to find the source vm #{source_vm} (#{Fission::VM.path(source_vm)})", 1 
        end

        if Fission::VM.exists? target_vm
          Fission::ui.output_and_exit "The target vm #{target_vm} already exists", 1
        end

        Fission::VM.clone source_vm, target_vm

        Fission.ui.output ''
        Fission.ui.output 'Clone complete!'
      end

      def self.help
       %Q{
clone source_vm target_vm
  source_vm - vm to clone from
  target_vm - new vm to create}
      end

    end
  end
end
