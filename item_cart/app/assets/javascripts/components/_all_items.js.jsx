var AllItems = React.createClass({

  handleDelete(itemId) {
    this.props.handleDelete(itemId)
  },

  handleUpdate(newItem) {
    this.props.handleUpdate(newItem)
  },

  render() {
    var items = this.props.items.map(item => {
      return (
        <div key={item.id}>
          <Item item={item}
                handleDelete={this.handleDelete}
                onUpdate={this.handleUpdate}/>
        </div>
      )
    })

    return (
      <div>
        {items}
      </div>
    )
  }
})