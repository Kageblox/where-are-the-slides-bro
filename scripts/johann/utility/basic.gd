class_name JBasicUtil extends Object

static func get_nearest_parent_of_class(node: Node, class_type: Variant) -> Node:
	var current_parent = node.get_parent()
	while current_parent != null:
		if is_instance_of(current_parent, class_type):
			return current_parent
		current_parent = current_parent.get_parent()
	return null
