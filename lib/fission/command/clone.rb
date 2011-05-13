module Fission
  class Command
    class Clone
      def self.execute(args)
        source_vm = args.first
        target_vm = args[1]

        Fission::Vm.exists? source_vm
        Fission::Vm.exists? target_vm

        Fission::Vm.clone source_vm, target_vm
      end
    end
  end
end
