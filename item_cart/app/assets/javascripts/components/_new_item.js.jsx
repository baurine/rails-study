var NewItem = React.createClass({

  handleClick() {
    var name = this.refs.name.value
    var desc = this.refs.desc.value
    console.log("name:" + name + " desc:" + desc)
    $.ajax({
      url: 'api/v1/items',
      type: 'POST',
      data: { item: { name: name, description: desc } },
      success: (item) => {
        // console.log("it works!", item)
        this.props.handleSubmit(item)
      }
    })
  },

  render() {
    return (
      <div>
        <input ref="name" placeholder="Enter the name of the item"/>
        <input ref="desc" placeholder="Enter the description of the item"/>
        <button onClick={this.handleClick}>Submit</button>
      </div>
    )
  }
})