import 'package:game_tools_lib/core/utils/scaled_bounds.dart';
import 'package:poe_shared/domain/panel/item_holder.dart';



// any panel that groups together item fields like stash tab, inventory, etc
// always created for default 2560x1440 dimensions as size relations!

base class ItemArea {

  // x/y is mostly used as an offset to the first field and width/height mostly as the field width/height
  // but sub classes may also provide custom larger fields!

  // in double here, because size might be 0.5, but children have int bounds!
  final ScaledBounds<double> offsetSize;


  // sorted by columns and then rows under them
  final int columns;

  // depends on sub classes how many rows a column has
  final int rows;

  // gets filled depending on sub classes
  final List<ItemHolder> children;




  // access to children at first ---- col   and then | row.  zero based
  ItemHolder atPos(int col, int row) => children.elementAt(col * rows + row);

  ItemHolder atIndex(int i) => children.elementAt(i);

}