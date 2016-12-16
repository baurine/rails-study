var Body = React.createClass({
  getInitialState() {
    return {
      items: []
    }
  },
  
  componentDidMount() {
    $.getJSON('/api/v1/items.json', (response) => {
      this.setState({items: response})
    })
  },

  handleSubmit(item) {
    var newItems = this.state.items.concat(item)
    this.setState({items: newItems})
  },

  handleDelete(itemId) {
    $.ajax({
      url: `/api/v1/items/${itemId}`,
      type: 'DELETE',
      success: () => {
        this.removeItem(itemId)
      }
    })
  },

  handleUpdate(newItem) {
    $.ajax({
      url: `/api/v1/items/${newItem.id}`,
      type: 'PUT',
      data: { item: newItem },
      success: () => {
        this.updateItem(newItem)
      }
    })
  },

  removeItem(itemId) {
    var newItems = this.state.items.filter(item => item.id != itemId)
    this.setState({items: newItems})
  },

  updateItem(newItem) {
    var newItems = this.state.items.map(item => {
      if (item.id != newItem.id) {
        return item
      } else {
        return newItem
      }
    })
    this.setState({items: newItems})
  },

  render() {
    return (
      <div>
        <NewItem handleSubmit={this.handleSubmit}/>
        <AllItems items={this.state.items} 
                  handleDelete={this.handleDelete}
                  handleUpdate={this.handleUpdate}/>
      </div>
    )
  }
})