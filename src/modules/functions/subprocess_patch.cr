# Workaround for a gi-crystal generator bug in
# Gio::Subprocess#wait_check_async: the generated body passes the Crystal
# `callback` proc (and `cancellable` object) to the C call instead of the
# built C function pointer (and pointer), so calling it fails to compile.
# Same fix pattern as file_launcher_patch.cr. Used by the Windows
# completion path (Windows has no waitpid).
class Gio::Subprocess
  def wait_check_async(cancellable : Gio::Cancellable?, &callback : Gio::AsyncReadyCallback) : Nil
    cancellable_val = if cancellable.nil?
                        Pointer(Void).null
                      else
                        cancellable.to_unsafe
                      end
    user_data = ::Box.box(callback)
    callback_val = ->(gobject : Void*, result : Void*, box : Void*) {
      unboxed_callback = ::Box(Gio::AsyncReadyCallback).unbox(box)
      GICrystal::ClosureDataManager.deregister(box)
      unboxed_callback.call(typeof(self).new(gobject, :none), Gio::AbstractAsyncResult.new(result, :none))
    }.pointer

    LibGio.g_subprocess_wait_check_async(to_unsafe, cancellable_val, callback_val, user_data)
  end
end
