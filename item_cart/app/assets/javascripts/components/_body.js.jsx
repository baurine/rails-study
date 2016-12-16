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

  render() {
    return (
      <div>
        <NewItem handleSubmit={this.handleSubmit}/>
        <AllItems items={this.state.items}/>
      </div>
    )
  }
})