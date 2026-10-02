# Workaround for a gi-crystal generator bug in
# Gtk::FileLauncher#open_containing_folder (and similar async methods):
# the generated body passes the Crystal `callback` proc to the C call
# instead of the built C function pointer, so calling it fails to
# compile. This override copies the generated code with the variable
# properly separated (same pattern as the working Gtk::FileDialog#save).
class Gtk::FileLauncher
  def open_containing_folder(parent : Gtk::Window?, cancellable : Gio::Cancellable?, &callback : Gio::AsyncReadyCallback) : Nil
    parent_val = if parent.nil?
                   Pointer(Void).null
                 else
                   parent.to_unsafe
                 end
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

    LibGtk.gtk_file_launcher_open_containing_folder(to_unsafe, parent_val, cancellable_val, callback_val, user_data)
  end
end
