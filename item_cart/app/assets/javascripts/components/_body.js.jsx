var Body = React.createClass({
  getInitialState() {
    return {
      items: this.props.items || []
    }
  },
  
  componentDidMount() {
    // the Body component will be pre-render by server when you access '/items' url
    // verify the js code run in client, whether it can retrive the init data supplied by server
    // the init data will be included in the html data
    console.log(this.props.items)
    console.log(this.state.items)

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