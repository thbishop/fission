module Fission
  class Command
    class Clone
      def self.execute(args)
        source_vm = args.first
        target_vm = args[1]

        unless Fission::Vm.exists? source_vm
          Fission.ui.output_and_exit "Unable to find the source vm #{source_vm}", 1 
        end

        if Fission::Vm.exists? target_vm
          Fission::ui.output_and_exit "The target vm #{target_vm} already exists", 1
        end

        Fission::Vm.clone source_vm, target_vm
      end
    end
  end
end
