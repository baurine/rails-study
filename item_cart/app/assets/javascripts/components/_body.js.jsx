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

  removeItem(itemId) {
    var newItems = this.state.items.filter(item => item.id != itemId)
    this.setState({items: newItems})
  },

  render() {
    return (
      <div>
        <NewItem handleSubmit={this.handleSubmit}/>
        <AllItems items={this.state.items} handleDelete={this.handleDelete}/>
      </div>
    )
  }
})